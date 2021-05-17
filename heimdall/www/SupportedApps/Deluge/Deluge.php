<?php namespace App\SupportedApps\Deluge;

use GuzzleHttp\Exception\GuzzleException;
use GuzzleHttp\Client;
use Illuminate\Support\Arr;

class Deluge extends \App\SupportedApps implements \App\EnhancedApps {

    //protected $login_first = true; // Uncomment if api requests need to be authed first
    protected $method = 'POST';  // Uncomment if requests to the API should be set by POST

    function __construct() {
        $this->jar = new \GuzzleHttp\Cookie\CookieJar; // Uncomment if cookies need to be set
    }

    public function login()
    {
        $password = $this->config->password;
        $attrs = [
            'body' => '{"method": "auth.login", "params": ["'.$password.'"], "id": 1}',
            'cookies' => $this->jar,
            'headers'  => ['content-type' => 'application/json', 'Accept' => 'application/json']
        ];
        return parent::appTest($this->url('json'), $attrs);
    }

    public function test()
    {
        $test = $this->login();
        if($test->code === 200) {
            $data = json_decode($test->response);
            if(!isset($data->result) || is_null($data->result) || $data->result == false) {
                $test->status = 'Failed: Invalid Credentials';
            } 
        } 
        echo $test->status;

    }

    public function livestats()
    {
        $test = $this->login();
        $status = 'inactive';
        $attrs = [
            'body' => '{"method": "web.update_ui", "params": [["none"], {}], "id": 1}',
            'cookies' => $this->jar,
            'headers'  => ['content-type' => 'application/json', 'Accept' => 'application/json']
        ];
        $res = parent::execute($this->url('json'), $attrs);
        $details = json_decode($res->getBody());

        $data = [];

        if($details) {
            $states = $details->result->filters->state;
            $download_rate = $details->result->stats->download_rate ?? 0;
            $upload_rate = $details->result->stats->upload_rate ?? 0;
            $data['download_rate'] = format_bytes($download_rate, false, ' <span>', '/s</span>');
            $data['upload_rate'] = format_bytes($upload_rate, false, ' <span>', '/s</span>');
            $data['seed_count'] = self::getState($states, 'Seeding');
            $data['leech_count'] = self::getState($states, 'Downloading');
            $status = (self::getState($states, 'Active') > 0) ? 'active' : 'inactive';
        }

        return parent::getLiveStats($status, $data);
       
    }

    public function url($endpoint)
    {
        $api_url = parent::normaliseurl($this->config->url).$endpoint;
        return $api_url;
    }

    protected static function getState(array $states, string $wantedState, int $default = 0): int {
        $state = Arr::first($states, function (array $state) use ($wantedState) {
            return $state[0] == $wantedState;
        });

        return Arr::get($state, 1, $default);
    }
}
