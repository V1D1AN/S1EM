<?php namespace App\SupportedApps\HDHomeRun;

class HDHomeRun extends \App\SupportedApps implements \App\EnhancedApps {

    public $config;

    //protected $login_first = true; // Uncomment if api requests need to be authed first
    //protected $method = 'POST';  // Uncomment if requests to the API should be set by POST

    function __construct() {
        //$this->jar = new \GuzzleHttp\Cookie\CookieJar; // Uncomment if cookies need to be set
    }

    public function test()
    {
        //echo $this->url('lineup.json?show=found');
        $test = parent::appTest($this->url('lineup.json?show=found'));
        echo $test->status;
    }

    public function livestats()
    {
        $status = 'inactive';
        $res = parent::execute($this->url('lineup.json?show=found'));
        $details = json_decode($res->getBody());

        $data = [];

        if($details) {
             $channel_count = count($details);
             $data['number_of_channels'] = number_format($channel_count);
             $status = 'active';
        }

        $res = parent::execute($this->url('tuners.html'));
        $tunersBody = $res->getBody();
        if($tunersBody) {
            $exp = "/<tr>\\s*<td>([^<]+)<\/td>\\s*<td>([^<]+)<\/td><\/tr>/mi";
            preg_match_all($exp, $tunersBody, $matches, PREG_SET_ORDER, 0);;
            $inUse = 0;
            $totalTuners = 0;
            $match_count = count($matches);
            for ($i = 0; $i < $match_count; $i++) {
                if (count($matches[$i]) >= 2) {
                    if ($matches[$i][2] != "none" && $matches[$i][2] != "not in use") {
                        $inUse++;
                    }
                }
                $totalTuners++;
            }
            $data['tuners_in_use'] = number_format($inUse);
            $data['tuners_total'] = number_format($totalTuners);
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