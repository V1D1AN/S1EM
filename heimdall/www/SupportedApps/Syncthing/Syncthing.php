<?php namespace App\SupportedApps\Syncthing;

class Syncthing extends \App\SupportedApps implements \App\EnhancedApps {

    public $config;

    //protected $login_first = true; // Uncomment if api requests need to be authed first
    //protected $method = 'POST';  // Uncomment if requests to the API should be set by POST

    function __construct() {
        //$this->jar = new \GuzzleHttp\Cookie\CookieJar; // Uncomment if cookies need to be set
    }

    function get_request_attrs() {
        $attrs['headers'] = ["X-API-Key" => $this->config->apikey];
        return $attrs;
    }

    public function test()
    {
        $attrs = $this->get_request_attrs();
        $test = parent::appTest($this->url('/rest/system/version'), $attrs);
        echo $test->status;
    }

    public function livestats()
    {
        $data = [];
        $needed_files = 0;
        $needed_bytes = 0;
        $status = 'inactive';
        $attrs = $this->get_request_attrs();

        # first get a list of folders
        $res = parent::execute($this->url('/rest/stats/folder'), $attrs);
        $details = json_decode($res->getBody());

        foreach ($details as $folder => $folder_status) {
            $folder_db_res = parent::execute($this->url('/rest/db/status?folder=${folder}'), $attrs);
            $folder_db = json_decode($folder_db_res->getBody());

            if ($folder_db) {
                $needed_files += $folder_db["needFiles"];
                $needed_bytes += $folder_db["needBytes"];
            }
        }

        if ($needed_files || $needed_bytes) {
            $status = 'active';
        }

        $data['needed_files'] = $needed_files;
        $data['needed_bytes'] = $needed_bytes;
        return parent::getLiveStats($status, $data);
    }
    public function url($endpoint)
    {
        $api_url = parent::normaliseurl($this->config->url).$endpoint;
        return $api_url;
    }
}
