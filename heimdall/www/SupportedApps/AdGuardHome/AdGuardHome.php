<?php namespace App\SupportedApps\AdGuardHome;

class AdGuardHome extends \App\SupportedApps implements \App\EnhancedApps {

    public $config;

    //protected $login_first = true; // Uncomment if api requests need to be authed first
    //protected $method = 'POST';  // Uncomment if requests to the API should be set by POST

    function __construct() {
        //$this->jar = new \GuzzleHttp\Cookie\CookieJar; // Uncomment if cookies need to be set
    }

    public function test()
    {
        $test = parent::appTest($this->url('/control/stats'));
        echo $test->status;
    }

    public function livestats()
    {
        $status = 'inactive';
        $res = parent::execute($this->url('/control/stats'));
        $details = json_decode($res->getBody());

        $data = [];
        if($details) {
            // format has been changed in AdguardHome v0.99.0
            if (is_array($details->dns_queries)) {
                $data['dns_queries'] = number_format(array_sum($details->dns_queries));
                $data['blocked_filtering'] = number_format(array_sum($details->blocked_filtering));
            } else {
                $data['dns_queries'] = number_format($details->dns_queries);
                $data['blocked_filtering'] = number_format($details->blocked_filtering);
            }
        }

        return parent::getLiveStats($status, $data);
    }
    public function url($endpoint)
    {
        $api_url = parent::normaliseurl($this->config->url);
        $username = $this->config->username;
        $password = $this->config->password;
        $rebuild_url = str_replace('http://', 'http://'.$username.':'.$password.'@', $api_url);
        $rebuild_url = str_replace('https://', 'https://'.$username.':'.$password.'@', $rebuild_url);
        $rebuild_url = rtrim($rebuild_url, '/');

        $api_url = $rebuild_url.$endpoint;
        return $api_url;
    }
}