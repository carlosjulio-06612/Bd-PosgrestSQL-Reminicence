-- Insert default genres
INSERT INTO reminicence_schema.genres (name, description) VALUES
('Rock', 'Rock music genre'),
('Pop', 'Pop music genre'),
('Hip Hop', 'Hip Hop and Rap music'),
('Electronic', 'Electronic and EDM music'),
('Jazz', 'Jazz music genre'),
('Classical', 'Classical music'),
('R&B', 'Rhythm and Blues'),
('Country', 'Country music'),
('Latin', 'Latin music genres'),
('Indie', 'Independent music')
ON CONFLICT (name) DO NOTHING;