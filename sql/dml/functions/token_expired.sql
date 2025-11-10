-- Function: Check if Spotify token is expired
CREATE OR REPLACE FUNCTION reminicence_schema.is_spotify_token_expired(p_user_id INTEGER)
RETURNS BOOLEAN AS $$
DECLARE
    v_expires_at TIMESTAMP;
BEGIN
    SELECT expires_at INTO v_expires_at
    FROM reminicence_schema.spotify_user_tokens
    WHERE user_id = p_user_id;
    
    IF v_expires_at IS NULL THEN
        RETURN TRUE;
    END IF;
    
    RETURN v_expires_at <= CURRENT_TIMESTAMP;
END;
$$ LANGUAGE plpgsql;