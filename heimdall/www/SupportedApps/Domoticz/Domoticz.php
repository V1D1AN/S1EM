<?php namespace App\SupportedApps\Domoticz;

class Domoticz extends \App\SupportedApps implements \App\EnhancedApps {

    public $config;

    //protected $login_first = true; // Uncomment if api requests need to be authed first
    //protected $method = 'POST';  // Uncomment if requests to the API should be set by POST

    function __construct() {
        //$this->jar = new \GuzzleHttp\Cookie\CookieJar; // Uncomment if cookies need to be set
    }

    public function test()
    {
        $test = parent::appTest($this->url('type=command&param=getversion'));
        echo $test->status;
    }

    public function livestats()
    {
        $status = 'inactive';
        $res = parent::execute($this->url('type=devices&rid='.$this->config->deviceidx));
        $details = json_decode($res->getBody());

        $data = [];

        if($details) {
            $data['today'] = $details->result[0]->CounterToday ?? 0;
            $data['usage'] = $details->result[0]->Usage ?? 0;
        }

        return parent::getLiveStats($status, $data);
        
    }
    public function url($endpoint)
    {
        $api_url = parent::normaliseurl($this->config->url).'json.htm?'.$endpoint;
        return $api_url;
    }
}
