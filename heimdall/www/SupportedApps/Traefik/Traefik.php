<?php namespace App\SupportedApps\Traefik;

use GuzzleHttp\Exception\GuzzleException;
use GuzzleHttp\Client;
use Illuminate\Support\Collection;

class Traefik extends \App\SupportedApps implements \App\EnhancedApps {

    public function getRequestAttrs()
    {
        $username = $this->getConfigValue('username', null);
        $password = $this->getConfigValue('password', null);
        $ignoreTls = $this->getConfigValue('ignore_tls', false);

        $isLoginNeeded =
            !is_null($username) && !empty($username)
            && !is_null($password) && !empty($password);

        $attrs['headers'] = [ 'Accept' => 'application/json'];
        if($isLoginNeeded) {
            $attrs['auth'] = [ $username, $password ];
        }
        if($ignoreTls) {
            $attrs['verify'] = false;
        }

        return $attrs;
    }

    public function test()
    {
        $attrs = $this->getRequestAttrs();
        $test = parent::appTest($this->url('api/version'), $attrs);

        echo $test->status;
    }

    public function livestats()
    {
        $apiEndpoints = collect([
            'httpRouters' => 'api/http/routers',
            'httpServices' => 'api/http/services',
            'tcpRouters' => 'api/tcp/routers',
            'tcpServices' => 'api/tcp/services'
        ]);

        $status = 'active';
        $attrs = $this->getRequestAttrs();


        $responses = $apiEndpoints->mapWithKeys(function ($endpoint, $key) use ($attrs) {
            $response = parent::execute($this->url($endpoint), $attrs);
            $body = json_decode($response->getBody());
            $bodyCollection = collect($body);

            return [ $key => [
                'data' => $bodyCollection->filter(function ($value, $key) { return $value->status === 'enabled'; })->count(),
                'total' => $bodyCollection->count(),
            ] ];
        });


        $data = $this->getViewData($this->getConfigValue('fields', 'E'), $responses);
        return parent::getLiveStats($status, $data);
    }

    public function getViewData($config, $responses)
    {
        $nullValue = [ 'data' => 0, 'total' => 0 ];

        switch ($config) {
            /* HTTP routers/services only */
            case 'H':
                return [
                    'left' => [
                        'title' => 'Routers',
                        'data' => $responses->get('httpRouters', $nullValue)['data'],
                        'total' => $responses->get('httpRouters', $nullValue)['total'],
                    ],
                    'right' => [
                        'title' => 'Services',
                        'data' => $responses->get('httpServices', $nullValue)['data'],
                        'total' => $responses->get('httpServices', $nullValue)['total'],
                    ],
                ];
                break;

            /* TCP routers/services only */
            case 'T':
                return [
                    'left' => [
                        'title' => 'Routers',
                        'data' => $responses->get('tcpRouters', $nullValue)['data'],
                        'total' => $responses->get('tcpRouters', $nullValue)['total'],
                    ],
                    'right' => [
                        'title' => 'Services',
                        'data' => $responses->get('tcpServices', $nullValue)['data'],
                        'total' => $responses->get('tcpServices', $nullValue)['total'],
                    ],
                ];

            /* Routers only */
            case 'R':
                return [
                    'left' => [
                        'title' => 'HTTP',
                        'data' => $responses->get('httpRouters', $nullValue)['data'],
                        'total' => $responses->get('httpRouters', $nullValue)['total'],
                    ],
                    'right' => [
                        'title' => 'TCP',
                        'data' => $responses->get('tcpRouters', $nullValue)['data'],
                        'total' => $responses->get('tcpRouters', $nullValue)['total'],
                    ],
                ];

            /* Services only */
            case 'S':
                return [
                    'left' => [
                        'title' => 'HTTP',
                        'data' => $responses->get('httpServices', $nullValue)['data'],
                        'total' => $responses->get('httpServices', $nullValue)['total'],
                    ],
                    'right' => [
                        'title' => 'TCP',
                        'data' => $responses->get('tcpServices', $nullValue)['data'],
                        'total' => $responses->get('tcpServices', $nullValue)['total'],
                    ],
                ];
            
            /* Everything */
            default:
                return [
                    'left' => [
                        'title' => 'Routers',
                        'data' => $responses->get('httpRouters', $nullValue)['data'] + $responses->get('tcpRouters', $nullValue)['data'],
                        'total' => $responses->get('httpRouters', $nullValue)['total'] + $responses->get('tcpRouters', $nullValue)['total'],
                    ],
                    'right' => [
                        'title' => 'Services',
                        'data' => $responses->get('httpServices', $nullValue)['data'] + $responses->get('tcpServices', $nullValue)['data'],
                        'total' => $responses->get('httpServices', $nullValue)['total'] + $responses->get('tcpServices', $nullValue)['total'],
                    ],
                ];
        }
    }

    public function url($endpoint)
    {
        $api_url = parent::normaliseurl($this->config->url).$endpoint;
        return $api_url;
    }

    public function getConfigValue($key, $default=null)
    {
        return (isset($this->config) && isset($this->config->$key)) ? $this->config->$key : $default;
    }

}

