<?php namespace App\SupportedApps\AlarmPI;

class AlarmPI extends \App\SupportedApps implements \App\EnhancedApps {

    public $config;

    //protected $login_first = true; // Uncomment if api requests need to be authed first
    //protected $method = 'POST';  // Uncomment if requests to the API should be set by POST

    function __construct() {
        //$this->jar = new \GuzzleHttp\Cookie\CookieJar; // Uncomment if cookies need to be set
    }

    public function test()
    {
        // $test = parent::appTest($this->url('getSensors.json'), $this->attrs);
        $res = parent::execute($this->url('getSensors.json'), $this->attrs);
        echo $res->getBody();
    }

    public function livestats()
    {
        $status = 'inactive';

        $res = parent::execute($this->url('getSensors.json'), $this->attrs);
        $details = json_decode($res->getBody());
        $activesensors = 0;

        foreach ($details->sensors as $key => $value) {
            if ($value->enabled && $value->alert){
                $activesensors += 1;
            }
        }

        $data = [];
        if ($details->triggered){
            $alarmstatus = 'Intruder';
        } else if ($details->alarmArmed){
            $alarmstatus = 'Armed';
        } else {
            $alarmstatus = 'Disarmed';
        }
        $data['alarm_status'] = $alarmstatus;
        $data['alarm_sensors'] = $activesensors;
        return parent::getLiveStats($status, $data);
        
    }
    public function url($endpoint)
    {
        $this->attrs = ['auth'=> [$this->config->username, $this->config->password, 'Basic']];
        $api_url = parent::normaliseurl($this->config->url).$endpoint;
        return $api_url;
    }
}
