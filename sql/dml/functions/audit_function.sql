--##################################################
--#            AUDIT TRIGGER FUNCTION              #
--##################################################

-- Function: reminicence_schema.audit_function
-- Purpose: Enhanced generic trigger function to log INSERT, UPDATE, and DELETE operations
--          with support for backend application user tracking.
-- Description:
--     - functionality with OLD/NEW row conversion to JSONB
--     - Extracts the first identifier column ending in '_id' for record tracking
--     - Captures context like user agent, API endpoint, and request ID
--     - Backwards compatible with existing triggers
-- Usage:
--     - Set session variables from your backend before DML operations:
--       SELECT set_config('audit.app_user_id', '123', false);
--       SELECT set_config('audit.app_user_email', 'user@example.com', false);
--       SELECT set_config('audit.app_user_role', 'admin', false);
--       SELECT set_config('audit.user_agent', 'Mozilla/5.0...', false);
--       SELECT set_config('audit.api_endpoint', '/api/products/123', false);
--       SELECT set_config('audit.request_id', 'req-uuid-123', false);
-- Note:
--     - This function must be triggered AFTER DML operations
--     - Session variables are optional - function works without them for backwards compatibility

CREATE OR REPLACE FUNCTION reminicence_schema.audit_function()
RETURNS TRIGGER AS $$
DECLARE
    record_id INTEGER;
    old_data JSONB;
    new_data JSONB;
    app_user_id_val INTEGER;
    app_user_email_val VARCHAR(255);
    app_user_role_val VARCHAR(50);
    user_agent_val TEXT;
    api_endpoint_val VARCHAR(255);
    request_id_val VARCHAR(100);
    connection_ip_val INET;

BEGIN
    IF (TG_OP = 'DELETE') THEN
        old_data := to_jsonb(OLD);
        new_data := NULL;
        SELECT value::INTEGER INTO record_id
        FROM jsonb_each_text(to_jsonb(OLD))
        WHERE key ~ '_id$'
        LIMIT 1;
    ELSIF (TG_OP = 'UPDATE') THEN
        old_data := to_jsonb(OLD);
        new_data := to_jsonb(NEW);
        SELECT value::INTEGER INTO record_id
        FROM jsonb_each_text(to_jsonb(NEW))
        WHERE key ~ '_id$'
        LIMIT 1;
    ELSIF (TG_OP = 'INSERT') THEN
        old_data := NULL;
        new_data := to_jsonb(NEW);
        SELECT value::INTEGER INTO record_id
        FROM jsonb_each_text(to_jsonb(NEW))
        WHERE key ~ '_id$'
        LIMIT 1;
    END IF;
    BEGIN
        app_user_id_val := NULLIF(current_setting('audit.app_user_id', true), '')::INTEGER;
    EXCEPTION WHEN OTHERS THEN
        app_user_id_val := NULL;
    END;
    
    BEGIN
        app_user_email_val := NULLIF(current_setting('audit.app_user_email', true), '');
    EXCEPTION WHEN OTHERS THEN
        app_user_email_val := NULL;
    END;
    
    BEGIN
        app_user_role_val := NULLIF(current_setting('audit.app_user_role', true), '');
    EXCEPTION WHEN OTHERS THEN
        app_user_role_val := NULL;
    END;
    
    BEGIN
        user_agent_val := NULLIF(current_setting('audit.user_agent', true), '');
    EXCEPTION WHEN OTHERS THEN
        user_agent_val := NULL;
    END;
    
    BEGIN
        api_endpoint_val := NULLIF(current_setting('audit.api_endpoint', true), '');
    EXCEPTION WHEN OTHERS THEN
        api_endpoint_val := NULL;
    END;
    
    BEGIN
        request_id_val := NULLIF(current_setting('audit.request_id', true), '');
    EXCEPTION WHEN OTHERS THEN
        request_id_val := NULL;
    END;
    BEGIN
        connection_ip_val := NULLIF(current_setting('audit.connection_ip', true), '')::INET;
    EXCEPTION WHEN OTHERS THEN
        connection_ip_val := NULL;
    END;
    INSERT INTO reminicence_schema.audit_log (
        db_user_name, 
        app_user_id,         
        app_user_email,         
        app_user_role,        
        action_type,
        table_name,
        record_id,
        old_values,
        new_values,
        connection_ip,
        user_agent,
        api_endpoint,           
        request_id       
    ) VALUES (
        current_user,                 
        app_user_id_val,               
        app_user_email_val,          
        app_user_role_val,         
        TG_OP,                        
        TG_TABLE_NAME,                
        record_id,                    
        old_data,                        
        new_data,                        
        connection_ip_val,
        user_agent_val,                
        api_endpoint_val,              
        request_id_val                 
    );

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;