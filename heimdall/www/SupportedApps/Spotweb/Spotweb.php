<?php namespace App\SupportedApps\Spotweb;

class Spotweb extends \App\SupportedApps implements \App\EnhancedApps {

    public $config;

    function __construct() {
        $this->jar = new \GuzzleHttp\Cookie\CookieJar;
    }

    public function login()
    {
        $username = $this->config->username;
        $password = $this->config->password;

        if (!isset($username) || empty($username) || !isset($password) || empty($password))
            return;

        $attrs = [
            'cookies' => $this->jar
        ];
        $res = parent::execute($this->url('?page=login'), $attrs);
        $content = (string) $res->getBody(true);
        preg_match("/name=\"loginform\[xsrfid\]\" value=\"([^\"]+)/", $content, $matches);
        $xsrfid = $matches[1];

        $attrs = [
            'form_params' => [
                'loginform' => [
                    'username' => $username,
                    'password' => $password,
                    'xsrfid' => $xsrfid,
                    'submitlogin' => 'Login',
                ]
            ],
            'cookies' => $this->jar,
            'headers' => ['content-type' => 'application/x-www-form-urlencoded']
        ];
        $res = parent::execute($this->url('?page=login'), $attrs, false, 'POST');
    }

    public function test()
    {
        $this->login();
        
        $attrs = [
            'cookies' => $this->jar
        ];
        $test = parent::appTest($this->url('?page=statistics'), $attrs);
        echo $test->status;
    }

    public function livestats()
    {
        $this->login();

        $status = 'inactive';
        $attrs = [
            'cookies' => $this->jar
        ];
        $res = parent::execute($this->url('?page=statistics'), $attrs);
        $content = (string) $res->getBody(true);

        $data = [];
        if (preg_match("/Last update: ([^\<]+)/", $content, $matches) && count($matches) > 1) {
            $status = 'active';
            $data['last_update'] = trim($matches[1]);
        }
        return parent::getLiveStats($status, $data);
    }

    public function url($endpoint)
    {
        $api_url = parent::normaliseurl($this->config->url).$endpoint;
        return $api_url;
    }
}
