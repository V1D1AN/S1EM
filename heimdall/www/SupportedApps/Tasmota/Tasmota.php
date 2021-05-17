<?php namespace App\SupportedApps\Tasmota;

class Tasmota extends \App\SupportedApps implements \App\EnhancedApps {

    public $config;

    //protected $login_first = true; // Uncomment if api requests need to be authed first
    //protected $method = 'POST';  // Uncomment if requests to the API should be set by POST

    function __construct() {
        //$this->jar = new \GuzzleHttp\Cookie\CookieJar; // Uncomment if cookies need to be set
    }

    public function test()
    {
        $test = parent::appTest($this->url('cm?cmnd=Status 8'));
        echo $test->status;
    }

    public function livestats()
    {
        $status = 'inactive';
        $res = parent::execute($this->url('cm?cmnd=Status 8'));
        $details = json_decode($res->getBody());

        $data = [];
		
		if($details) {
            $data['temperature'] = number_format($details->StatusSNS->AM2301->Temperature,1);
            $data['humidity'] = number_format($details->StatusSNS->AM2301->Humidity,1);
            $data['dewpoint'] = number_format($details->StatusSNS->AM2301->DewPoint,1);
        }
		
        return parent::getLiveStats($status, $data);
        
    }
    public function url($endpoint)
    {
        $api_url = parent::normaliseurl($this->config->url).$endpoint;
        return $api_url;
    }
}
