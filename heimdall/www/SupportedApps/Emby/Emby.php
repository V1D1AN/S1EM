<?php namespace App\SupportedApps\Emby;

class Emby extends \App\SupportedApps implements \App\EnhancedApps {

    public $config;

    function __construct() {
    }

    public function test()
    {
        $test = parent::appTest($this->url('System/Info'), $this->getAttrs());
        echo $test->status;
    }

    public function livestats()
    {
        $status = 'inactive';
        $res = parent::execute($this->url('/emby/Items/Counts'), $this->getAttrs());
        $result = json_decode($res->getBody());
        $details = ['visiblestats'=>[]];
        foreach($this->config->availablestats as $stat) {
        $newstat = new \stdClass();
        $newstat->title = self::getAvailableStats()[$stat];
        $newstat->value = $result->{$stat};
                $details['visiblestats'][] = $newstat;
        }
        return parent::getLiveStats($status, $details);
    }
    public function url($endpoint)
    {
        $api_url = parent::normaliseurl($this->config->url).$endpoint;
        return $api_url;
    }

    private function getAttrs() {
        return [
            'headers' => [
                'X-Emby-Token' => $this->config->password,
            ]
        ];
    }

    public static function getAvailableStats() {
        return [
            'MovieCount'=>'Movies',
            'SeriesCount'=>'Series',
            'EpisodeCount'=>'Episodes',
            'GameCount'=>'Games',
            'ArtistCount'=>'Artists',
            'ProgramCount'=>'Programs',
            'GameSystemCount'=>'GameSystems',
            'TrailerCount'=>'Trailers',
            'SongCount'=>'Songs',
            'AlbumCount'=>'Albums',
            'MusicVideoCount'=>'MusicVideos',
            'BoxSetCount'=>'BoxSets',
            'BookCount'=>'Books',
            'ItemCount'=>'Items',
        ];
    }
} 