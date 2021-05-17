<?php namespace App\SupportedApps\Ghost;
use Exception;

class Ghost extends \App\SupportedApps implements \App\EnhancedApps {
    public $config;

    function __construct() {
        $this->jar = new \GuzzleHttp\Cookie\CookieJar; // Uncomment if cookies need to be set
        $this->authorized = false;
    }

    public function test() {
        try {
            $this->auth();
            echo "Successfully communicated with the API";
        } catch (Exception $err) {
            echo "Error connecting to Ghost: ".$err->getMessage();
        }
    }

    public function auth() {
        if ($this->authorized) {
            return;
        }

        $this->authorized = false;

        $attrs = [
            'cookies' => $this->jar,
            'headers' => ['content-type' => 'application/json']
        ];
        $body["username"] = $this->config->username;
        $body["password"] = $this->config->password;
        $vars = [
                'http_errors' => false,
                'timeout' => 5,
                'body' => json_encode($body)
        ];

        $result = parent::execute($this->url('ghost/api/v3/admin/session'), $attrs, $vars, 'POST');

        if (null === $result) {
            throw new Exception("Error contacting the API");
        }

        if ($result->getStatusCode() !== 201) {
            switch ($result->getStatusCode()) {
                case 404:
                    throw new Exception("User is not found");
                case 422:
                    throw new Exception("Invalid credentials");
            }

            throw new Exception("Unknown error");
        }

        $this->authorized = true;
        return $result;
}

    public function livestats() {
        $status = 'inactive';

        $this->auth();

        $attrs = [
            'cookies' => $this->jar,
            'headers' => ['content-type' => 'application/json']
        ];
        $result = parent::execute($this->url('ghost/api/v3/admin/posts/'), $attrs, []);
        if (null === $result) {
            throw new Exception("Could not connect to Ghost");
        }

        $response = json_decode($result->getBody());
        $posts = $response->posts;
        $statuses = array_count_values(array_column($posts, 'status'));

        $data = [
            'draft' => isset($statuses['draft']) ? $statuses['draft'] : 0,
            'scheduled' => isset($statuses['scheduled']) ? $statuses['scheduled'] : 0,
            'published' => isset($statuses['published']) ? $statuses['published'] : 0
        ];
        $status = 'active';
        return parent::getLiveStats($status, $data);

    }

    public function url($endpoint) {
        $api_url = parent::normaliseurl($this->config->url).$endpoint;
        return $api_url;
    }
}