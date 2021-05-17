<?php namespace App\SupportedApps\Ombi;

class Ombi extends \App\SupportedApps implements \App\EnhancedApps {

    public $config;

    //protected $login_first = true; // Uncomment if api requests need to be authed first
    //protected $method = 'POST';  // Uncomment if requests to the API should be set by POST

    function __construct() {
        //$this->jar = new \GuzzleHttp\Cookie\CookieJar; // Uncomment if cookies need to be set
    }

    public function test()
    {
        $test = parent::appTest($this->url('api/v1/status'));
        echo $test->status;
    }

    public function livestats()
    {
        $status = 'inactive';
        $this->attrs['headers'] = ['ApiKey' => $this->config->apikey];
        $res = parent::execute($this->url('api/v1/request/count'), $this->attrs);
        $details = json_decode($res->getBody(), True);

        return parent::getLiveStats($status, $details);

    }
    public function url($endpoint)
    {
        $api_url = parent::normaliseurl($this->config->url).$endpoint;
        return $api_url;
    }
}
