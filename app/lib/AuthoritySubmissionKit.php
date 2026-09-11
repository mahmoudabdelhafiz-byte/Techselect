<?php
final class AuthoritySubmissionKit {
  public static function base(): array {
    return [
      'name'=>'TechSelectAI',
      'tagline'=>'AI-Powered Software & Technology Advisory',
      'short'=>'TechSelectAI helps businesses compare software and technology using structured requirements, evidence-backed product facts and transparent fit scoring.',
      'medium'=>'TechSelectAI is an AI-powered software and technology advisory platform that helps businesses structure technology requirements and evaluate suitable options using evidence-backed product data and deterministic scoring in curated categories.',
      'long'=>'TechSelectAI combines AI-assisted requirement interpretation with evidence-backed product data and deterministic scoring to help organizations evaluate software and technology options. Fit Score and Evidence Confidence are kept separate, and unknown or not-yet-verified claims are not treated as unsupported. TechSelectAI is operated by Barmageyat; ownership, sponsorship and commercial relationships are disclosed and kept separate from organic recommendation scoring.',
      'ownership'=>'TechSelectAI is operated by Barmageyat. Products developed by Barmageyat may appear in the catalog, but ownership, sponsorship and commercial relationships do not change organic recommendation scoring.',
      'boundaries'=>'Do not describe TechSelectAI as universally ranking the best software. Buyer-specific Fit Scores depend on stated requirements and available verified evidence. Do not imply endorsement, certification, partnership, customer proof or publication unless independently verified.',
      'homepage'=>'https://techselectai.com/',
      'about'=>'https://techselectai.com/about-techselectai',
      'methodology'=>'https://techselectai.com/methodology',
      'trust'=>'https://techselectai.com/trust',
      'logo'=>'https://techselectai.com/techselectai-logo.svg',
    ];
  }

  public static function tagged(string $source,string $medium='profile',string $campaign='external-authority'): string {
    $source=strtolower(trim($source));
    $source=preg_replace('/[^a-z0-9._-]+/','-',$source)?:'external';
    $medium=strtolower(trim($medium));
    $medium=preg_replace('/[^a-z0-9._-]+/','-',$medium)?:'profile';
    return 'https://techselectai.com/?'.http_build_query([
      'utm_source'=>$source,
      'utm_medium'=>$medium,
      'utm_campaign'=>$campaign,
    ],'', '&', PHP_QUERY_RFC3986);
  }

  public static function channels(): array {
    $b=self::base();
    return [
      'producthunt'=>[
        'name'=>'Product Hunt','status'=>'ready','link'=>self::tagged('producthunt','profile'),
        'headline'=>'AI-powered software and technology advisory for evidence-backed buying decisions',
        'description'=>$b['medium'],
        'notes'=>'Use factual product positioning only. Do not claim ranking superiority, awards, traction or customer counts unless separately verified.'
      ],
      'crunchbase'=>[
        'name'=>'Crunchbase','status'=>'ready','link'=>self::tagged('crunchbase','company-profile'),
        'headline'=>$b['tagline'],'description'=>$b['medium'],
        'notes'=>'Use Barmageyat as operator/parent organization where the profile supports ownership relationships.'
      ],
      'startupblink'=>[
        'name'=>'StartupBlink','status'=>'ready','link'=>self::tagged('startupblink','company-profile'),
        'headline'=>'Software & technology advisory platform','description'=>$b['medium'],
        'notes'=>'Do not claim ecosystem ranking or listing status until the external page is actually public.'
      ],
      'linkedin'=>[
        'name'=>'LinkedIn','status'=>'ready','link'=>self::tagged('linkedin','company-profile'),
        'headline'=>$b['tagline'],'description'=>$b['long'],
        'notes'=>'Company page description should stay consistent with the public About/Trust pages.'
      ],
      'wamda'=>[
        'name'=>'Wamda','status'=>'ready','link'=>self::tagged('wamda','publication','external-authority-editorial'),
        'headline'=>'Evidence-backed software buying and AI-assisted technology evaluation in MENA',
        'description'=>'TechSelectAI can contribute practical, non-promotional commentary on software evaluation, AI-assisted procurement, evidence quality, deployment tradeoffs and regional buyer requirements in MENA.',
        'notes'=>'Editorial pitch only. Lead with useful expertise and original methodology; do not ask for a backlink as the primary purpose.'
      ],
      'g2'=>[
        'name'=>'G2','status'=>'eligibility_check','link'=>self::tagged('g2','directory'),
        'headline'=>$b['tagline'],'description'=>$b['short'],
        'notes'=>'Confirm current category/provider eligibility before any listing. TechSelectAI is an advisory/discovery platform, not a conventional software vendor.'
      ],
      'capterra'=>[
        'name'=>'Capterra','status'=>'eligibility_check','link'=>self::tagged('capterra','directory'),
        'headline'=>$b['tagline'],'description'=>$b['short'],
        'notes'=>'Confirm provider/category eligibility before submitting. Do not force-fit TechSelectAI into an inaccurate software category.'
      ],
      'alternativeto'=>[
        'name'=>'AlternativeTo','status'=>'eligibility_check','link'=>self::tagged('alternativeto','directory'),
        'headline'=>$b['tagline'],'description'=>$b['short'],
        'notes'=>'Confirm whether an advisory/discovery platform is an appropriate listing type before submission.'
      ],
      'saashub'=>[
        'name'=>'SaaSHub','status'=>'eligibility_check','link'=>self::tagged('saashub','directory'),
        'headline'=>$b['tagline'],'description'=>$b['short'],
        'notes'=>'Confirm current listing eligibility before creating a profile.'
      ],
    ];
  }
}
