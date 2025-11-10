--##################################################
--#           DDL SCRIPT DOCUMENTATION             #
--##################################################
-- Database: Reminicence - Music Management System with Spotify Integration
-- Version: 2.2 - Adapted for Django Integration with Custom Schema
--
-- This version of the script is adapted for integration with the Django web framework,
-- assuming Django is configured to manage its tables within the 'reminicence_schema'.
-- The native 'users' table has been removed. All foreign key constraints now point
-- to the 'reminicence_schema.auth_user' table, which is created and managed by Django's
-- robust authentication system. This approach keeps all application-related tables,
-- including Django's, within a single, organized schema.
--
-- IMPORTANT: Ensure your Django database settings are configured to use the
-- 'reminicence_schema'. Run Django's 'migrate' command BEFORE executing this script
-- to ensure the 'reminicence_schema.auth_user' table exists.

--##################################################
--#              CORE TABLES                       #
--##################################################

-- REMOVED: The users table is now handled by Django.
-- Django will create a 'reminicence_schema.auth_user' table to manage users, passwords, and sessions.

-- Table: reminicence_schema.artists
-- Brief: Music artists from both local catalog and Spotify
CREATE TABLE reminicence_schema.artists (
    artist_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    country VARCHAR(50),
    formation_year INTEGER,
    biography TEXT,
    artist_type VARCHAR(30) CHECK (artist_type IN ('soloist', 'band', 'collective')),
    
    -- Spotify Integration Fields
    spotify_id VARCHAR(50) UNIQUE,
    spotify_url VARCHAR(255),
    image_url VARCHAR(500),
    popularity INTEGER CHECK (popularity BETWEEN 0 AND 100),
    followers INTEGER DEFAULT 0,
    data_source VARCHAR(20) NOT NULL DEFAULT 'local' CHECK (data_source IN ('local', 'spotify', 'hybrid')),
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Ensure Spotify artists have spotify_id
    CONSTRAINT chk_spotify_artist CHECK (
        (data_source = 'local' AND spotify_id IS NULL) OR
        (data_source IN ('spotify', 'hybrid') AND spotify_id IS NOT NULL)
    )
);

-- Table: reminicence_schema.genres
-- Brief: Music genres catalog
CREATE TABLE reminicence_schema.genres (
    genre_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    spotify_id VARCHAR(50) UNIQUE
);

-- Table: reminicence_schema.albums
-- Brief: Music albums with Spotify integration
CREATE TABLE reminicence_schema.albums (
    album_id SERIAL PRIMARY KEY,
    artist_id INTEGER NOT NULL,
    title VARCHAR(150) NOT NULL,
    release_year INTEGER CHECK (release_year BETWEEN 1900 AND EXTRACT(YEAR FROM CURRENT_DATE)),
    release_date DATE,
    record_label VARCHAR(100),
    album_type VARCHAR(30) CHECK (album_type IN ('studio', 'live', 'compilation', 'single', 'ep')),
    
    -- Spotify Integration Fields
    spotify_id VARCHAR(50) UNIQUE,
    spotify_url VARCHAR(255),
    cover_image_url VARCHAR(500),
    total_tracks INTEGER,
    data_source VARCHAR(20) NOT NULL DEFAULT 'local' CHECK (data_source IN ('local', 'spotify', 'hybrid')),
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_albums_artist FOREIGN KEY (artist_id) 
        REFERENCES reminicence_schema.artists (artist_id) 
        ON UPDATE CASCADE ON DELETE CASCADE
);

-- Table: reminicence_schema.devices
-- Brief: User devices for tracking playback
CREATE TABLE reminicence_schema.devices (
    device_id SERIAL PRIMARY KEY,
    device_name VARCHAR(100),
    device_type VARCHAR(30) NOT NULL CHECK (device_type IN ('mobile', 'computer', 'tablet', 'speaker', 'other')),
    operating_system VARCHAR(50),
    browser VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: reminicence_schema.songs
-- Brief: Individual songs supporting both local files and Spotify tracks
CREATE TABLE reminicence_schema.songs (
    song_id SERIAL PRIMARY KEY,
    album_id INTEGER NOT NULL,
    title VARCHAR(150) NOT NULL,
    duration INTEGER NOT NULL, -- Duration in milliseconds
    track_number INTEGER,
    disc_number INTEGER DEFAULT 1,
    composer VARCHAR(100),
    lyrics TEXT,
    explicit_content BOOLEAN DEFAULT FALSE,
    
    -- Local File Fields
    audio_path VARCHAR(255),
    file_size_mb DECIMAL(8,2),
    
    -- Spotify Integration Fields
    spotify_id VARCHAR(50) UNIQUE,
    spotify_url VARCHAR(255),
    preview_url VARCHAR(500), -- 30-second preview from Spotify
    isrc VARCHAR(20), -- International Standard Recording Code
    popularity INTEGER CHECK (popularity BETWEEN 0 AND 100),
    
    -- Source tracking
    data_source VARCHAR(20) NOT NULL DEFAULT 'local' CHECK (data_source IN ('local', 'spotify', 'youtube')),
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Must have at least one playback source
    CONSTRAINT chk_audio_source CHECK (
        audio_path IS NOT NULL OR preview_url IS NOT NULL
    ),
    CONSTRAINT fk_songs_album FOREIGN KEY (album_id) 
        REFERENCES reminicence_schema.albums (album_id) 
        ON UPDATE CASCADE ON DELETE CASCADE
);

-- Table: reminicence_schema.playlists
-- Brief: User-created playlists (can contain local and Spotify songs)
CREATE TABLE reminicence_schema.playlists (
    playlist_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    creation_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) NOT NULL DEFAULT 'private' CHECK (status IN ('public', 'private', 'collaborative')),
    cover_image_url VARCHAR(500),
    
    -- Spotify Sync Fields
    spotify_id VARCHAR(50) UNIQUE,
    spotify_snapshot_id VARCHAR(100),
    is_synced_with_spotify BOOLEAN DEFAULT FALSE,
    last_sync_date TIMESTAMP,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- MODIFIED: Point to Django's auth_user table within the application schema
    CONSTRAINT fk_playlists_user FOREIGN KEY (user_id) 
        REFERENCES reminicence_schema.auth_user (id) 
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT uk_playlist_user_name UNIQUE (name, user_id)
);


--##################################################
--#         RELATIONSHIP TABLES                    #
--##################################################

-- Table: reminicence_schema.song_genres
-- Brief: Many-to-many relationship between songs and genres
CREATE TABLE reminicence_schema.song_genres (
    song_id INTEGER NOT NULL,
    genre_id INTEGER NOT NULL,
    PRIMARY KEY (song_id, genre_id),
    
    CONSTRAINT fk_song_genres_song FOREIGN KEY (song_id) 
        REFERENCES reminicence_schema.songs (song_id) 
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_song_genres_genre FOREIGN KEY (genre_id) 
        REFERENCES reminicence_schema.genres (genre_id) 
        ON UPDATE CASCADE ON DELETE CASCADE
);

-- Table: reminicence_schema.playlist_songs
-- Brief: Songs in playlists with ordering
CREATE TABLE reminicence_schema.playlist_songs (
    playlist_id INTEGER NOT NULL,
    song_id INTEGER NOT NULL,
    position INTEGER NOT NULL,
    date_added TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    added_by_user_id INTEGER,
    PRIMARY KEY (playlist_id, song_id),
    
    CONSTRAINT fk_playlist_songs_playlist FOREIGN KEY (playlist_id) 
        REFERENCES reminicence_schema.playlists (playlist_id) 
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_playlist_songs_song FOREIGN KEY (song_id) 
        REFERENCES reminicence_schema.songs (song_id) 
        ON UPDATE CASCADE ON DELETE CASCADE,
    
    -- MODIFIED: Point to Django's auth_user table within the application schema
    CONSTRAINT fk_playlist_songs_user FOREIGN KEY (added_by_user_id)
        REFERENCES reminicence_schema.auth_user (id)
        ON UPDATE CASCADE ON DELETE SET NULL
);

-- Table: reminicence_schema.user_device
-- Brief: Links users to their devices
CREATE TABLE reminicence_schema.user_device (
    user_id INTEGER NOT NULL,
    device_id INTEGER NOT NULL,
    registration_date DATE NOT NULL DEFAULT CURRENT_DATE,
    last_access TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_reproduction_date TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    PRIMARY KEY (user_id, device_id),
    
    -- MODIFIED: Point to Django's auth_user table within the application schema
    CONSTRAINT fk_user_device_user FOREIGN KEY (user_id) 
        REFERENCES reminicence_schema.auth_user(id) 
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_user_device_devices FOREIGN KEY (device_id) 
        REFERENCES reminicence_schema.devices(device_id)  
        ON UPDATE CASCADE ON DELETE CASCADE
);

-- Table: reminicence_schema.playback_history
-- Brief: Complete playback history with ratings
CREATE TABLE reminicence_schema.playback_history (
    playback_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    song_id INTEGER NOT NULL,
    device_id INTEGER NOT NULL,
    playback_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed BOOLEAN NOT NULL DEFAULT FALSE,
    playback_duration INTEGER, -- How long the user listened (ms)
    rating INTEGER CHECK (rating BETWEEN 1 AND 5),
    skipped BOOLEAN DEFAULT FALSE,
    
    -- MODIFIED: Point to Django's auth_user table within the application schema
    CONSTRAINT fk_playback_history_user FOREIGN KEY (user_id) 
        REFERENCES reminicence_schema.auth_user (id) 
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_playback_history_song FOREIGN KEY (song_id) 
        REFERENCES reminicence_schema.songs (song_id) 
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_playback_history_device FOREIGN KEY (device_id) 
        REFERENCES reminicence_schema.devices (device_id) 
        ON UPDATE CASCADE ON DELETE CASCADE
);

--##################################################
--#         SPOTIFY INTEGRATION TABLES             #
--##################################################

-- Table: reminicence_schema.spotify_user_tokens
-- Brief: OAuth tokens for Spotify user authentication
CREATE TABLE reminicence_schema.spotify_user_tokens (
    token_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL UNIQUE,
    access_token TEXT NOT NULL,
    refresh_token TEXT,
    token_type VARCHAR(20) DEFAULT 'Bearer',
    expires_at TIMESTAMP NOT NULL,
    scope TEXT, -- Permissions granted by user
    spotify_user_id VARCHAR(100), -- User's Spotify ID
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- MODIFIED: Point to Django's auth_user table within the application schema
    CONSTRAINT fk_spotify_tokens_user FOREIGN KEY (user_id) 
        REFERENCES reminicence_schema.auth_user(id) 
        ON DELETE CASCADE
);

-- Table: reminicence_schema.spotify_api_cache
-- Brief: Cache for Spotify API responses to reduce API calls
CREATE TABLE reminicence_schema.spotify_api_cache (
    cache_id SERIAL PRIMARY KEY,
    cache_key VARCHAR(500) NOT NULL UNIQUE, -- Hash of endpoint + params
    endpoint VARCHAR(255) NOT NULL,
    query_params JSONB,
    response_data JSONB NOT NULL,
    cached_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    hit_count INTEGER DEFAULT 0
);

-- Table: reminicence_schema.spotify_sync_log
-- Brief: Track synchronization operations with Spotify
CREATE TABLE reminicence_schema.spotify_sync_log (
    sync_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    sync_type VARCHAR(50) NOT NULL, -- 'playlist_import', 'library_sync', etc.
    status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'in_progress', 'completed', 'failed')),
    items_processed INTEGER DEFAULT 0,
    items_total INTEGER,
    error_message TEXT,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    
    -- MODIFIED: Point to Django's auth_user table within the application schema
    CONSTRAINT fk_sync_log_user FOREIGN KEY (user_id)
        REFERENCES reminicence_schema.auth_user(id)
        ON DELETE CASCADE
);

--##################################################
--#         USER FAVORITES & INTERACTIONS          #
--##################################################

-- Table: reminicence_schema.user_favorite_songs
-- Brief: User's favorite/liked songs
CREATE TABLE reminicence_schema.user_favorite_songs (
    user_id INTEGER NOT NULL,
    song_id INTEGER NOT NULL,
    favorited_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, song_id),
    
    -- MODIFIED: Point to Django's auth_user table within the application schema
    CONSTRAINT fk_favorite_songs_user FOREIGN KEY (user_id)
        REFERENCES reminicence_schema.auth_user(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_favorite_songs_song FOREIGN KEY (song_id)
        REFERENCES reminicence_schema.songs(song_id)
        ON DELETE CASCADE
);

-- Table: reminicence_schema.user_favorite_artists
-- Brief: User's favorite artists
CREATE TABLE reminicence_schema.user_favorite_artists (
    user_id INTEGER NOT NULL,
    artist_id INTEGER NOT NULL,
    favorited_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, artist_id),
    
    -- MODIFIED: Point to Django's auth_user table within the application schema
    CONSTRAINT fk_favorite_artists_user FOREIGN KEY (user_id)
        REFERENCES reminicence_schema.auth_user(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_favorite_artists_artist FOREIGN KEY (artist_id)
        REFERENCES reminicence_schema.artists(artist_id)
        ON DELETE CASCADE
);

--##################################################
--#                AUDIT TABLE                     #
--##################################################
-- (Audit table remains unchanged as app_user_id does not have a FK constraint, which is correct for audit logs)
CREATE TABLE reminicence_schema.audit_log (
    audit_id SERIAL PRIMARY KEY,
    db_user_name VARCHAR(100) NOT NULL DEFAULT SESSION_USER,
    app_user_id INTEGER,                           
    app_user_email VARCHAR(255),                     
    app_user_role VARCHAR(50),
    action_type VARCHAR(10) NOT NULL CHECK (action_type IN ('INSERT', 'UPDATE', 'DELETE')), 
    timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    table_name VARCHAR(50) NOT NULL,                
    record_id INTEGER, 
    old_values JSONB,                               
    new_values JSONB, 
    connection_ip INET,               
    user_agent TEXT,                                 
    api_endpoint VARCHAR(255),      
    request_id VARCHAR(100),
    application_name VARCHAR(50) DEFAULT 'reminicence_app',
    environment VARCHAR(20) DEFAULT 'production' CHECK (environment IN ('development', 'staging', 'production'))
);

--##################################################
--#              CREATE INDEXES                    #
--##################################################

-- Artist indexes
CREATE INDEX idx_artists_name_search ON reminicence_schema.artists (LOWER(name));
CREATE INDEX idx_artists_spotify_id ON reminicence_schema.artists(spotify_id) WHERE spotify_id IS NOT NULL;
CREATE INDEX idx_artists_data_source ON reminicence_schema.artists(data_source);
CREATE INDEX idx_artists_popularity ON reminicence_schema.artists(popularity DESC) WHERE popularity IS NOT NULL;
CREATE INDEX idx_artists_country_name ON reminicence_schema.artists (country, name);

-- Album indexes
CREATE INDEX idx_albums_artist_id ON reminicence_schema.albums(artist_id);
CREATE INDEX idx_albums_title_search ON reminicence_schema.albums (LOWER(title));
CREATE INDEX idx_albums_spotify_id ON reminicence_schema.albums(spotify_id) WHERE spotify_id IS NOT NULL;
CREATE INDEX idx_albums_release_year ON reminicence_schema.albums(release_year DESC);
CREATE INDEX idx_albums_data_source ON reminicence_schema.albums(data_source);

-- Song indexes
CREATE INDEX idx_songs_album_id ON reminicence_schema.songs(album_id);
CREATE INDEX idx_songs_title_search ON reminicence_schema.songs (LOWER(title));
CREATE INDEX idx_songs_spotify_id ON reminicence_schema.songs(spotify_id) WHERE spotify_id IS NOT NULL;
CREATE INDEX idx_songs_data_source ON reminicence_schema.songs(data_source);
CREATE INDEX idx_songs_popularity ON reminicence_schema.songs(popularity DESC) WHERE popularity IS NOT NULL;
CREATE INDEX idx_songs_isrc ON reminicence_schema.songs(isrc) WHERE isrc IS NOT NULL;

-- Genre indexes
CREATE INDEX idx_genres_name_lower ON reminicence_schema.genres (LOWER(name));

-- Playlist indexes
CREATE INDEX idx_playlists_user_id ON reminicence_schema.playlists(user_id);
CREATE INDEX idx_playlists_name_lower ON reminicence_schema.playlists (LOWER(name));
CREATE INDEX idx_playlists_status ON reminicence_schema.playlists(status);
CREATE INDEX idx_playlists_spotify_id ON reminicence_schema.playlists(spotify_id) WHERE spotify_id IS NOT NULL;
CREATE INDEX idx_playlists_creation_date ON reminicence_schema.playlists(creation_date DESC);

-- Playlist songs indexes
CREATE INDEX idx_playlist_songs_playlist_position ON reminicence_schema.playlist_songs (playlist_id, position);
CREATE INDEX idx_playlist_songs_song_id ON reminicence_schema.playlist_songs(song_id);
CREATE INDEX idx_playlist_songs_date_added ON reminicence_schema.playlist_songs(date_added DESC);

-- Playback history indexes (for analytics)
CREATE INDEX idx_playback_history_user_id ON reminicence_schema.playback_history(user_id);
CREATE INDEX idx_playback_history_song_id ON reminicence_schema.playback_history(song_id);
CREATE INDEX idx_playback_history_device_id ON reminicence_schema.playback_history(device_id);
CREATE INDEX idx_playback_history_playback_date ON reminicence_schema.playback_history(playback_date DESC);
CREATE INDEX idx_playback_history_user_date ON reminicence_schema.playback_history (user_id, playback_date DESC);
CREATE INDEX idx_playback_history_song_date ON reminicence_schema.playback_history (song_id, playback_date DESC);
CREATE INDEX idx_playback_history_completed_rating ON reminicence_schema.playback_history (completed, rating, playback_date);

-- User device indexes
CREATE INDEX idx_user_device_user_id ON reminicence_schema.user_device(user_id);
CREATE INDEX idx_user_device_device_id ON reminicence_schema.user_device(device_id);
CREATE INDEX idx_user_device_last_access ON reminicence_schema.user_device(last_access DESC);

-- Spotify integration indexes
CREATE INDEX idx_spotify_tokens_user ON reminicence_schema.spotify_user_tokens(user_id);
CREATE INDEX idx_spotify_tokens_expires ON reminicence_schema.spotify_user_tokens(expires_at);
CREATE INDEX idx_spotify_cache_key ON reminicence_schema.spotify_api_cache(cache_key);
CREATE INDEX idx_spotify_cache_expires ON reminicence_schema.spotify_api_cache(expires_at);
CREATE INDEX idx_spotify_sync_log_user ON reminicence_schema.spotify_sync_log(user_id);
CREATE INDEX idx_spotify_sync_log_status ON reminicence_schema.spotify_sync_log(status);

-- Favorites indexes
CREATE INDEX idx_favorite_songs_user ON reminicence_schema.user_favorite_songs(user_id);
CREATE INDEX idx_favorite_songs_song ON reminicence_schema.user_favorite_songs(song_id);
CREATE INDEX idx_favorite_artists_user ON reminicence_schema.user_favorite_artists(user_id);
CREATE INDEX idx_favorite_artists_artist ON reminicence_schema.user_favorite_artists(artist_id);

-- Audit log indexes
CREATE INDEX idx_audit_log_app_user_id ON reminicence_schema.audit_log (app_user_id);
CREATE INDEX idx_audit_log_timestamp ON reminicence_schema.audit_log (timestamp DESC);
CREATE INDEX idx_audit_log_table_name ON reminicence_schema.audit_log (table_name);
CREATE INDEX idx_audit_log_action_type ON reminicence_schema.audit_log (action_type);
CREATE INDEX idx_audit_log_record_id ON reminicence_schema.audit_log (table_name, record_id);

--##################################################
--#              USEFUL VIEWS                      #
--##################################################

-- View: Complete song information with artist and album
CREATE VIEW reminicence_schema.v_songs_complete AS
SELECT 
    s.song_id,
    s.title AS song_title,
    s.duration,
    s.track_number,
    s.explicit_content,
    s.spotify_id AS song_spotify_id,
    s.preview_url,
    s.popularity AS song_popularity,
    s.data_source,
    
    al.album_id,
    al.title AS album_title,
    al.release_year,
    al.cover_image_url,
    al.spotify_id AS album_spotify_id,
    
    ar.artist_id,
    ar.name AS artist_name,
    ar.image_url AS artist_image_url,
    ar.spotify_id AS artist_spotify_id
    
FROM reminicence_schema.songs s
JOIN reminicence_schema.albums al ON s.album_id = al.album_id
JOIN reminicence_schema.artists ar ON al.artist_id = ar.artist_id;

-- View: User's most played songs
CREATE VIEW reminicence_schema.v_user_top_songs AS
SELECT 
    ph.user_id,
    s.song_id,
    s.title AS song_title,
    ar.name AS artist_name,
    COUNT(*) AS play_count,
    AVG(ph.rating) AS avg_rating,
    MAX(ph.playback_date) AS last_played
FROM reminicence_schema.playback_history ph
JOIN reminicence_schema.songs s ON ph.song_id = s.song_id
JOIN reminicence_schema.albums al ON s.album_id = al.album_id
JOIN reminicence_schema.artists ar ON al.artist_id = ar.artist_id
WHERE ph.completed = TRUE
GROUP BY ph.user_id, s.song_id, s.title, ar.name;

--##################################################
--#              END OF DDL SCRIPT                 #
--##################################################

-- To verify schema creation:
-- SELECT table_name FROM information_schema.tables 
-- WHERE table_schema = 'reminicence_schema' ORDER BY table_name;