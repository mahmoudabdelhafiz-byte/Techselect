<?php

require_once __DIR__.'/BestCategorySeo.php';
require_once __DIR__.'/RegionalCategorySeo.php';

/**
 * Internal SEO research links for already-qualified public surfaces.
 *
 * This helper does not create eligibility or ranking. It only links to pages that
 * existing SEO qualification classes already consider indexable/publication-ready.
 */
final class SeoTopicCluster
{
    public static function categoryLinks(PDO $pdo,string $categorySlug):array
    {
        $links=[];
        try {
            $best=BestCategorySeo::page($pdo,$categorySlug);
            if($best){
                $links[]=['kind'=>'best','label'=>'Evidence-qualified '.$best['category']['name'].' software','path'=>$best['path']];
            }
        } catch(Throwable $e) {}

        try {
            foreach(RegionalCategorySeo::linksForCategory($pdo,$categorySlug) as $regional){
                $links[]=[
                    'kind'=>'regional',
                    'label'=>$regional['category']['name'].' availability in '.$regional['country']['name'],
                    'path'=>$regional['path'],
                ];
            }
        } catch(Throwable $e) {}

        return $links;
    }
}
