<?php namespace App\SupportedApps\WaniKani;

class WaniKani extends \App\SupportedApps implements \App\EnhancedApps {

    public $config;

    //protected $login_first = true; // Uncomment if api requests need to be authed first
    //protected $method = 'POST';  // Uncomment if requests to the API should be set by POST

    function __construct() {
        //$this->jar = new \GuzzleHttp\Cookie\CookieJar; // Uncomment if cookies need to be set
    }

    /**
     * Try to obtain user information to test login
     */
    public function login()
    {
        $api_token = $this->config->username;
        $attrs = [
            'headers' => ['Authorization' => 'Bearer '.$api_token]
        ];
        return parent::execute($this->url('user'), $attrs, false, 'GET');
    }

    /**
     * "Login" the user and return the username
     */
    public function test()
    {
        $test = $this->login();
        if($test->getStatusCode() === 200 && $test->getBody()) {
            $wk_resp = json_decode($test->getBody());
            echo "Hello ".$wk_resp->data->username;
        } else {
            echo "Failed";
        }
    }

    /**
     * Obtain the user summary and return the total of Reviews and Lessons
     */
    public function livestats()
    {
        $status = 'inactive';
        $now = \Carbon\Carbon::now();
        $api_token = $this->config->username;
        $attrs = [
            'headers' => ['Authorization' => 'Bearer '.$api_token]
        ];
        $res =  parent::execute($this->url('summary'), $attrs, false, 'GET');
        $details = json_decode($res->getBody());
        $data = [ "lessons" => 0, "reviews" => 0 ];
        foreach($details->data->lessons as $lesson)
        {
            $available_at = \Carbon\Carbon::createFromTimeString($lesson->available_at);
            if($now >= $available_at)
            {
                $data["lessons"] += count($lesson->subject_ids);
            }
        }
        foreach($details->data->reviews as $review)
        {
            $available_at = \Carbon\Carbon::createFromTimeString($review->available_at);
            if($now >= $available_at)
            {
                $data["reviews"] += count($review->subject_ids);
            }
        }

        return parent::getLiveStats($status, $data);

    }

    /**
     * Build api url
     */
    public function url($endpoint)
    {
        $api_url = parent::normaliseurl('https://api.wanikani.com/v2/').$endpoint;
        return $api_url;
    }
}
