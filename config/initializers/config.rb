#
# Load application configuration defaults.
# Then, overwrite them with customizations.
#



### Define defaults
#
CLAHUB_CONFIG_DEFAULTS = Hash.new
CLAHUB_CONFIG_DEFAULTS['oauth_context_title'] = 'CLAHub'
CLAHUB_CONFIG_DEFAULTS['html_header_title']   = 'CLAHub'
CLAHUB_CONFIG_DEFAULTS['page_header_brand']   = 'CLAHub'
CLAHUB_CONFIG_DEFAULTS['favicon_uri']         = '/favicon.ico'



### Read configuration file, if exists
#
# Also, if someone speified content under environment key, use that
#
localConfigFile = "#{Rails.root}/config/config.yml"
if ! File.exist?(localConfigFile) then
    $CLAHUB_CONFIG_LOCAL = Hash.new
else
    $CLAHUB_CONFIG_LOCAL = YAML.load_file(localConfigFile)

    if $CLAHUB_CONFIG_LOCAL.has_key?(Rails.env) then
        $CLAHUB_CONFIG_LOCAL = $CLAHUB_CONFIG_LOCAL[Rails.env]
    end
end



### Merge local configuration
#
$CLAHUB_CONFIG = CLAHUB_CONFIG_DEFAULTS
$CLAHUB_CONFIG = $CLAHUB_CONFIG.merge($CLAHUB_CONFIG_LOCAL)
