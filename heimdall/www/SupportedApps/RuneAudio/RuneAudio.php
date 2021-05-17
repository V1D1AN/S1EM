<?php namespace App\SupportedApps\RuneAudio;

class RuneAudio extends \App\SupportedApps implements \App\EnhancedApps {

    public $config;

    //protected $login_first = true; // Uncomment if api requests need to be authed first
    //protected $method = 'POST';  // Uncomment if requests to the API should be set by POST

    function __construct() {
        //$this->jar = new \GuzzleHttp\Cookie\CookieJar; // Uncomment if cookies need to be set
    }

    public function test()
    {
        $test = parent::appTest($this->url('status'));
        echo $test->status;
    }

    public function livestats()
    {
        $status = 'inactive';
        $res = parent::execute($this->url('currentsong'));

        $array = explode("\n", $res->getBody());
        foreach($array as $item) {
            $item_array = explode(": ", $item);
            if ($item_array[0] == 'Artist') {
                $artist = $item_array[1];
            } elseif ($item_array[0] == 'Title') {
                $song_title = $item_array[1];
            }
        }

        $data = [];

        $data['artist'] = $artist ?? 'None';
        $data['song_title'] = $song_title ?? 'None';

        return parent::getLiveStats($status, $data);
        
    }

    public function url($endpoint)
    {
        $api_url = parent::normaliseurl($this->config->url).'command/?cmd='.$endpoint;
        return $api_url;
    }
}
