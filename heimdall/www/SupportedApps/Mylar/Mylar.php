<?php namespace App\SupportedApps\Mylar;

class Mylar extends \App\SupportedApps implements \App\EnhancedApps {

    public $config;

    //protected $login_first = true; // Uncomment if api requests need to be authed first
    //protected $method = 'POST';  // Uncomment if requests to the API should be set by POST

    function __construct() {
        //$this->jar = new \GuzzleHttp\Cookie\CookieJar; // Uncomment if cookies need to be set
    }

    public function test()
    {
        $test = parent::appTest($this->url('getVersion'));
        echo $test->status;
    }

    public function livestats()
    {
        $status = 'inactive';
        $data = [];

        $missing = json_decode(parent::execute($this->url('getWanted'))->getBody());
        $upcoming = json_decode(parent::execute($this->url('getUpcoming'))->getBody());

        $data = [];

        $data['missing'] = count($missing) ?? 0;
        $data['upcoming'] = count($upcoming) ?? 0;

        return parent::getLiveStats($status, $data);
        
    }
    
    public function url($endpoint)
    {
        $api_url = parent::normaliseurl($this->config->url).'api?apikey='.$this->config->apikey.'&cmd='.$endpoint;
        return $api_url;
    }

}
