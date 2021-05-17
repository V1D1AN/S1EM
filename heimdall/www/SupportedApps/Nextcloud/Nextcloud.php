<?php namespace App\SupportedApps\Nextcloud;

class Nextcloud extends \App\SupportedApps implements \App\EnhancedApps {

    public $config;

    //protected $login_first = true; // Uncomment if api requests need to be authed first
    //protected $method = 'POST';  // Uncomment if requests to the API should be set by POST

    function __construct() {
        //$this->jar = new \GuzzleHttp\Cookie\CookieJar; // Uncomment if cookies need to be set
    }

    public function getHeaders()
    {
        $username = $this->config->username;
        $password = $this->config->password;

        $attrs['headers'] = [
            'Authorization' => 'Basic '.base64_encode($username.":".$password),
            'OCS-APIRequest' => 'true',
        ];
        return $attrs;
    }

    public function test()
    {
        $username = $this->config->username;

        $test = parent::appTest($this->url('/ocs/v1.php/cloud/users/'.$username.'?format=json'), $this->getHeaders());
        echo $test->status;
    }

    public function livestats()
    {
        $status = 'inactive';

        $username = $this->config->username;
        $res = parent::execute($this->url('/ocs/v1.php/cloud/users/'.$username.'?format=json'), $this->getHeaders());
        $details = json_decode($res->getBody());

        $data = ['visiblestats' => []];

        if ($details) 
        {
            foreach($this->config->availablestats as $stat) {
                if (!isset(self::getAvailableStats()[$stat])) continue;
    
                $newstat = new \stdClass();
                $newstat->title = self::getAvailableStats()[$stat];
                $newstat->value = self::formatNumberUsingStat($stat, $details->ocs->data->quota->{$stat});
    
                $data['visiblestats'][] = $newstat;
            }
        }

        return parent::getLiveStats($status, $data);
        
    }
    public function url($endpoint)
    {
        $api_url = parent::normaliseurl($this->config->url);
        return $api_url.$endpoint;
    }

    public static function getAvailableStats()
    {
        return [
            'relative'=>'Usage',
            'used'=>'Used Space',
            'free'=>'Free Space',
            'total'=>'Total Space',
        ];
    }

    private static function formatNumberUsingStat($stat, $number)
    {
        if (!isset($number)) return 'N/A';

        switch ($stat) {
            case 'free':
            case 'used':
            case 'total':
                return format_bytes($number, false, '<span>', '</span>');
            case 'relative':
                return number_format($number, 1).'<span>%</span>';
            default:
                return number_format($number);
        }
    }
}
