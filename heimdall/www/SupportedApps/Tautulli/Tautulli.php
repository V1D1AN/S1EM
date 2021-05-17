<?php namespace App\SupportedApps\Tautulli;

class Tautulli extends \App\SupportedApps implements \App\EnhancedApps {

    public $config;

    //protected $login_first = true; // Uncomment if api requests need to be authed first
    //protected $method = 'POST';  // Uncomment if requests to the API should be set by POST

    function __construct() {
        //$this->jar = new \GuzzleHttp\Cookie\CookieJar; // Uncomment if cookies need to be set
    }

    public function test()
    {
        $test = parent::appTest($this->url('arnold'));
        if($test->code === 200) {
            $data = json_decode($test->response);
            if(isset($data->error) && !empty($data->error)) {
                $test->status = 'Failed: '.$data->error;
            } 
        } 

        echo $test->status;
    }

    public function livestats()
    {
        $status = 'inactive';
        $res = parent::execute($this->url('get_activity'));
        $details = json_decode($res->getBody());

        $data['stream_count'] = $details->response->data->stream_count ?? 0;

        return parent::getLiveStats($status, $data);
        
    }
    public function url($endpoint)
    {
        $apikey = $this->config->apikey;
        $api_url = parent::normaliseurl($this->config->url).'api/v2?apikey='.$apikey.'&cmd='.$endpoint;

        return $api_url;
    }
}
