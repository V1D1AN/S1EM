<?php namespace App\SupportedApps\PRTG;

class PRTG extends \App\SupportedApps implements \App\EnhancedApps {

    public $config;

    //protected $login_first = true; // Uncomment if api requests need to be authed first
    //protected $method = 'POST';  // Uncomment if requests to the API should be set by POST

    function __construct() {
        //$this->jar = new \GuzzleHttp\Cookie\CookieJar; // Uncomment if cookies need to be set
    }

    public function test()
    {
		$username = $this->config->username;
		$passhash = $this->config->passhash;
        $test = parent::appTest($this->url('api/getstatus.htm?id=0&username='.$username.'&passhash='.$passhash));
        echo $test->status;
    }

    public function livestats()
    {
		$username = $this->config->username;
		$passhash = $this->config->passhash;
        $status = 'inactive';
        $res = parent::execute($this->url('api/getstatus.htm?id=0&username='.$username.'&passhash='.$passhash));
        $details = json_decode($res->getBody());

        $data = [];
		
		if($details) {
			if (empty($details->Alarms)) {$data['alarms'] = 0;} else {$data['alarms'] = number_format($details->Alarms);}
			if (empty($details->AckAlarms)) {$data['alarmsack'] = 0;} else {$data['alarmsack'] = number_format($details->AckAlarms);}
            if (empty($details->WarnSens)) {$data['warnings'] = 0;} else {$data['warnings'] = number_format($details->WarnSens);}
			if (empty($details->UnusualSens)) {$data['unusuals'] = 0;} else {$data['unusuals'] = number_format($details->UnusualSens);}	
			if (empty($details->UpSens)) {$data['ups'] = 0;} else {$data['ups'] = number_format($details->UpSens);}
        }
		
        return parent::getLiveStats($status, $data);
        
    }
    public function url($endpoint)
    {
        $api_url = parent::normaliseurl($this->config->url).$endpoint;
        return $api_url;
    }
}
