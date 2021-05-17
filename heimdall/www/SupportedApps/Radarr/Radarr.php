<?php namespace App\SupportedApps\Radarr;

class Radarr extends \App\SupportedApps implements \App\EnhancedApps {

    public $config;

    //protected $login_first = true; // Uncomment if api requests need to be authed first
    //protected $method = 'POST';  // Uncomment if requests to the API should be set by POST

    function __construct() {
        //$this->jar = new \GuzzleHttp\Cookie\CookieJar; // Uncomment if cookies need to be set
    }

    public function test()
    {
        $test = parent::appTest($this->url('system/status'));
        echo $test->status;
    }

    public function livestats()
    {
        $status = 'inactive';
        $data = [];

        $movies = json_decode(parent::execute($this->url('movie'))->getBody());
        $queue = json_decode(parent::execute($this->url('queue'))->getBody());

        $collect = collect($movies);
        $missing = $collect->where('hasFile', false);

        $data = [];
        if($missing || $queue) {
            $data['missing'] = $missing->count() ?? 0;
            $data['queue'] = count($queue) ?? 0;
        }

        return parent::getLiveStats($status, $data);
        
    }

    public function url($endpoint)
    {
        $api_url = parent::normaliseurl($this->config->url).'api/'.$endpoint.'?apikey='.$this->config->apikey;
        return $api_url;
    }
}
