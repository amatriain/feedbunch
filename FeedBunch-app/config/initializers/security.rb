# Per-form CSRF tokens, to protect against code injection in forms created by javascript
Rails.application.config.action_controller.per_form_csrf_tokens = true

# Check the HTTP Origin header as additional defense against CSRF.
Rails.application.config.action_controller.forgery_protection_origin_check = true