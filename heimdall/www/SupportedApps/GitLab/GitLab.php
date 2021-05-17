<?php namespace App\SupportedApps\GitLab;

class GitLab extends \App\SupportedApps implements \App\EnhancedApps {

    public $config;

    //protected $login_first = true; // Uncomment if api requests need to be authed first
    //protected $method = 'POST';  // Uncomment if requests to the API should be set by POST

    function __construct() {
        //$this->jar = new \GuzzleHttp\Cookie\CookieJar; // Uncomment if cookies need to be set
    }

    public function test()
    {
        if(!empty($this->config->health_apikey))
        {
            $test = parent::appTest($this->url('/-/readiness?token='.$this->config->health_apikey.'&all=1'));
            echo $test->status;
        }
    }

    public function livestats()
    {
        $status = 'inactive';
        $data = [];
        
        if(!empty($this->config->health_apikey))
        {
            $res1 = parent::execute($this->url('/-/readiness?token='.$this->config->health_apikey.'&all=1'));
            $details1 = json_decode($res1->getBody());
            if($details1)
            {
                $data['status'] = $details1->status;
                $status = $details1->status;
            }
        }
        
        if(!empty($this->config->private_apikey))
        {
            $call_header['headers'] = ['PRIVATE-TOKEN' => $this->config->private_apikey];
            $res2 = parent::execute($this->url('/api/v4/application/statistics'), $call_header);
            $details2 = json_decode($res2->getBody());
            if($details2 && isset($details2->projects) && isset($details2->active_users))
            {
                 $data['count_projects'] = $details2->projects;
                 $data['count_users'] = $details2->active_users;
            }
        }
        
        return parent::getLiveStats($status, $data);
        
    }
    public function url($endpoint)
    {
        $api_url = parent::normaliseurl($this->config->url).$endpoint;
        return $api_url;
    }
}
