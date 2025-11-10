--##################################################
--#         CREATE AUDIT TRIGGERS                  #
--##################################################

-- Triggers for core tables
CREATE TRIGGER trg_audit_users
    AFTER INSERT OR UPDATE OR DELETE ON reminicence_schema.auth_user
    FOR EACH ROW EXECUTE FUNCTION reminicence_schema.audit_function();

CREATE TRIGGER trg_audit_artists
    AFTER INSERT OR UPDATE OR DELETE ON reminicence_schema.artists
    FOR EACH ROW EXECUTE FUNCTION reminicence_schema.audit_function();

CREATE TRIGGER trg_audit_songs
    AFTER INSERT OR UPDATE OR DELETE ON reminicence_schema.songs
    FOR EACH ROW EXECUTE FUNCTION reminicence_schema.audit_function();