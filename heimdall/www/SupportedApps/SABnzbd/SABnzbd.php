<?php namespace App\SupportedApps\SABnzbd;

class SABnzbd extends \App\SupportedApps implements \App\EnhancedApps {

    public $config;

    //protected $login_first = true; // Uncomment if api requests need to be authed first
    //protected $method = 'POST';  // Uncomment if requests to the API should be set by POST

    function __construct() {
        //$this->jar = new \GuzzleHttp\Cookie\CookieJar; // Uncomment if cookies need to be set
    }

    public function test()
    {
        $test = parent::appTest($this->url('queue'));
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
        $res = parent::execute($this->url('queue'));
        $details = json_decode($res->getBody());

        $data = [];

        if($details) {
            $size = $details->queue->mbleft;
            $rate = $details->queue->kbpersec;
            $data['queue_size'] = format_bytes($size*1000*1000, false, ' <span>', '</span>');
            $data['current_speed'] = format_bytes($rate*1000, false, ' <span>', '/s</span>');
            $status = ($size > 0 || $rate > 0) ? 'active' : 'inactive';
        }

        return parent::getLiveStats($status, $data);
        
    }
    public function url($endpoint)
    {
        $apikey = $this->config->apikey;
        $api_url = parent::normaliseurl($this->config->url).'api?output=json&apikey='.$apikey.'&mode='.$endpoint;
        return $api_url;
    }
}
