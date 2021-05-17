<?php namespace App\SupportedApps\Artifactory;

class Artifactory extends \App\SupportedApps implements \App\EnhancedApps {

    public $config;

    //protected $login_first = true; // Uncomment if api requests need to be authed first
    //protected $method = 'POST';  // Uncomment if requests to the API should be set by POST

    function __construct() {
        //$this->jar = new \GuzzleHttp\Cookie\CookieJar; // Uncomment if cookies need to be set
    }

    public function test()
    {
        $attrs = [
            'headers' => ['X-JFrog-Art-Api' => $this->config->apiKey]
        ];
        echo $this->config->apiKey;
        $test = parent::appTest($this->url('api/storageinfo'), $attrs);

        echo $test->status;
    }

    public function livestats()
    {
        $status = 'inactive';
        $attrs = [
            'headers' => ['X-JFrog-Art-Api' => $this->config->apiKey]
        ];
        $res = parent::execute($this->url('api/storageinfo'), $attrs);
        $details = json_decode($res->getBody());

        $data = [];
        if($details) {
            $data['artifacts_size'] = $details->binariesSummary->artifactsSize;
            $data['artifacts_count'] = $details->binariesSummary->artifactsCount;
            $status = 'active';
        }
        return parent::getLiveStats($status, $data);
        
    }
    public function url($endpoint)
    {
        $api_url = parent::normaliseurl($this->config->url).$endpoint;
        return $api_url;
    }
}
