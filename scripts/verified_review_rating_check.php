<?php
require_once __DIR__.'/../app/lib/VerifiedReviewRating.php';

function check($condition, $message) {
    if (!$condition) {fwrite(STDERR, "FAIL: {$message}\n"); exit(1);} 
}

$none = VerifiedReviewRating::calculate([]);
check($none['rating_5'] === null, 'No approved reviews should not publish a rating.');

$pending = VerifiedReviewRating::calculate([
    ['overall_rating'=>5,'moderation_status'=>'pending','verification_level'=>'admin_verified']
]);
check($pending['approved_review_count'] === 0, 'Pending review must be excluded.');

$approved = VerifiedReviewRating::calculate([
    ['overall_rating'=>5,'moderation_status'=>'approved','verification_level'=>'admin_verified','submitted_at'=>date('Y-m-d')],
    ['overall_rating'=>4,'moderation_status'=>'approved','verification_level'=>'proof_of_use_verified','submitted_at'=>date('Y-m-d')],
    ['overall_rating'=>2,'moderation_status'=>'approved','verification_level'=>'email_verified','submitted_at'=>'2022-01-01'],
]);
check($approved['approved_review_count'] === 3, 'Approved reviews should be counted.');
check($approved['rating_5'] >= 1 && $approved['rating_5'] <= 5, 'Rating must remain within 1-5.');
check($approved['weighted_review_count'] > 0, 'Weighted count should be positive.');

check(VerifiedReviewRating::verificationWeight('admin_verified') > VerifiedReviewRating::verificationWeight('email_verified'), 'Higher verification should carry more weight.');

$singleFive = VerifiedReviewRating::calculate([
    ['overall_rating'=>5,'moderation_status'=>'approved','verification_level'=>'admin_verified','submitted_at'=>date('Y-m-d')]
]);
check($singleFive['rating_5'] < 5, 'Bayesian prior must prevent a single five-star review from displaying a perfect 5.0.');

fwrite(STDOUT, "Verified review rating checks passed.\n");
