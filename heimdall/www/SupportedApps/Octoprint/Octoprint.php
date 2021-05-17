<?php namespace App\SupportedApps\Octoprint;

use Carbon\Carbon;

class Octoprint extends \App\SupportedApps implements \App\EnhancedApps {

    public $config;

    //protected $login_first = true; // Uncomment if api requests need to be authed first
    //protected $method = 'POST';  // Uncomment if requests to the API should be set by POST

    function __construct() {
    }

    public function test()
    {
        $attrs['headers'] = ['X-Api-Key' => $this->config->apikey];
        $test = parent::appTest($this->url('api/version'), $attrs);
        echo $test->status;
    }

    public function livestats()
    {
        $status = 'inactive';
        $attrs['headers'] = ['X-Api-Key' => $this->config->apikey];
        $res = parent::execute($this->url('api/job'), $attrs);
        $details = json_decode($res->getBody());

        $data = [];

        $progress = $details->progress->completion;

        $data['progress'] = @round($progress) ?? 0;
        $seconds = $details->progress->printTimeLeft;
        if($seconds === null) {
            $data['estimated'] = 'N/A';
        } elseif($seconds > 0) {
            $data['estimated'] = Carbon::now()->addSeconds($seconds)->diffForHumans();
        } else {
            $data['estimated'] = 'N/A';
        }
        

        $status = ($data['progress'] < 100 && $progress !== null) ? 'active' : 'inactive';

        return parent::getLiveStats($status, $data);
        
    }
    public function url($endpoint)
    {
        $api_url = parent::normaliseurl($this->config->url).$endpoint;
        return $api_url;
    }
}
