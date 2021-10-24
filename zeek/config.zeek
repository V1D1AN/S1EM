# All configuration must occur within this file.
# All other files may be overwritten during upgrade
module FileExtraction;

# Configure where extracted files will be stored
redef path = "/extract_files/";

# Configure 'plugins' that can be loaded
# these are shortcut modules to specify common
# file extraction policies. Example:
# @load ./plugins/extract-pe.bro
@load ./plugins/extract-common-exploit-types