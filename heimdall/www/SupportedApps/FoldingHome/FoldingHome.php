<?php namespace App\SupportedApps\FoldingHome;

class FoldingHome extends \App\SupportedApps implements \App\EnhancedApps {

    public $config;

    //protected $login_first = true; // Uncomment if api requests need to be authed first
    //protected $method = 'POST';  // Uncomment if requests to the API should be set by POST

    function __construct() {
        //$this->jar = new \GuzzleHttp\Cookie\CookieJar; // Uncomment if cookies need to be set
    }

    public function test()
    {
	$this->setSID();
	$test = parent::appTest($this->url($this->updateURI()));
        echo $test->status;
    }
    public function livestats()
    {
        $status = 'inactive';
	$this->setSID();
        $res = parent::execute($this->url($this->updateURI()));
        $details = json_decode($res->getBody(), true);
	$status = $details[1][1][0]["status"];
	$progress = isset($details[1][1][0]["percentdone"]) ? $details[1][1][0]["percentdone"] : "N/A";
	$eta = isset($details[1][1][0]["eta"]) ? $details[1][1][0]["eta"] : "N/A";

        $data = [
		"status" => $status,
		"progress" => $progress,
		"eta" => $eta
	];
        return parent::getLiveStats($status, $data);
    }

    public function url($endpoint)
    {
        $api_url = parent::normaliseurl($this->config->url).$endpoint;
        return $api_url;
    }
    public function setSID()
    {
	if (empty($this->sid)) {
                $rand = mt_rand() / mt_getrandmax();
                $res = parent::execute($this->url('api/session?_='.$rand), [], [], 'PUT');
                $this->sid = (string) $res->getBody();

		$query_data = [
			'sid' => $this->sid,
			'update_id' => 0,
			'update_rate' => 1,
			'update_path' => '/api/basic',
			'_' => time()
		];
		$res2 = parent::execute($this->url('api/updates/set'), ['query' => $query_data]);
		$query_data2 = [
			'sid' => $this->sid,
			'update_id' => 1,
			'update_rate' => 1,
			'update_path' => '/api/slots',
			'_' => time()
		];
		$res3 = parent::execute($this->url('api/updates/set'), ['query' => $query_data2]);
		$query_data3 = [
			'sid' => $this->sid,
			'_' => time()
		];
		$res4 = parent::execute($this->url('api/configured'), ['query' => $query_data3]);
	}
    }
    public function updateURI()
    {
	$query_url = 'api/updates?sid=';
	$query_url .= $this->sid;
	$query_url .= '&_=';
	$query_url .= time();
	return $query_url;
    }
}
