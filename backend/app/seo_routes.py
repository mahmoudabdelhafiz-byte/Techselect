from html import escape
from fastapi import APIRouter, HTTPException, Response
from psycopg.rows import dict_row
from .db import db_cursor
from .settings import settings

router = APIRouter()

@router.get('/robots.txt', include_in_schema=False)
def robots_txt():
    body = f'''User-agent: *\nAllow: /\nDisallow: /admin\nDisallow: /account\nDisallow: /api\nDisallow: /sign-in\nDisallow: /register\nDisallow: /verify-email\nDisallow: /advice\nSitemap: {settings.site_url.rstrip('/')}/sitemap.xml\n'''
    return Response(content=body, media_type='text/plain')

@router.get('/sitemap.xml', include_in_schema=False)
def sitemap_xml():
    base = settings.site_url.rstrip('/')
    with db_cursor() as cur:
        cur.row_factory = dict_row
        cur.execute("SELECT slug, updated_at FROM products WHERE status='active' ORDER BY slug")
        products = cur.fetchall()
        cur.execute("SELECT DISTINCT slug FROM capabilities WHERE is_active=true ORDER BY slug")
        capabilities = cur.fetchall()
        cur.execute("""
            SELECT p1.slug AS a, p2.slug AS b
            FROM products p1
            JOIN products p2 ON p1.category_id=p2.category_id AND p1.id<p2.id
            WHERE p1.status='active' AND p2.status='active'
            ORDER BY p1.slug,p2.slug
            LIMIT 200
        """)
        pairs = cur.fetchall()
    urls = [f'{base}/', f'{base}/software', f'{base}/methodology']
    urls += [f"{base}/software/{p['slug']}" for p in products]
    urls += [f"{base}/capabilities/{c['slug']}" for c in capabilities]
    urls += [f"{base}/compare/{min(x['a'],x['b'])}-vs-{max(x['a'],x['b'])}" for x in pairs]
    xml = '<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">' + ''.join(f'<url><loc>{escape(u)}</loc></url>' for u in urls) + '</urlset>'
    return Response(content=xml, media_type='application/xml')

@router.get('/api/public/software')
def public_software():
    with db_cursor() as cur:
        cur.row_factory = dict_row
        cur.execute("""
            SELECT p.slug,p.name,p.short_description,v.name AS vendor_name,c.name AS category_name,p.last_reviewed_at
            FROM products p
            LEFT JOIN vendors v ON v.id=p.vendor_id
            LEFT JOIN categories c ON c.id=p.category_id
            WHERE p.status='active'
            ORDER BY p.name
        """)
        return {'products': cur.fetchall()}

@router.get('/api/public/software/{slug}')
def public_product(slug: str):
    with db_cursor() as cur:
        cur.row_factory = dict_row
        cur.execute("""
            SELECT p.id,p.slug,p.name,p.short_description,p.website_url,p.last_reviewed_at,
                   v.name AS vendor_name,c.name AS category_name
            FROM products p
            LEFT JOIN vendors v ON v.id=p.vendor_id
            LEFT JOIN categories c ON c.id=p.category_id
            WHERE p.slug=%s AND p.status='active'
        """, (slug,))
        product = cur.fetchone()
        if not product:
            raise HTTPException(404, 'Product not found')
        cur.execute("""
            SELECT cap.slug,cap.name,m.name AS module_name,pc.support_status,pc.limitations,pc.confidence_score,pc.last_verified_at
            FROM product_capabilities pc
            JOIN capabilities cap ON cap.id=pc.capability_id
            JOIN modules m ON m.id=cap.module_id
            WHERE pc.product_id=%s AND pc.edition_id IS NULL
            ORDER BY m.name,cap.name
        """, (product['id'],))
        capabilities = cur.fetchall()
        cur.execute("""
            SELECT source_title,source_url,source_type,verification_status,confidence,checked_at
            FROM evidence_sources WHERE product_id=%s
            ORDER BY checked_at DESC
        """, (product['id'],))
        evidence = cur.fetchall()
    return {'product': product, 'capabilities': capabilities, 'evidence': evidence}

@router.get('/api/public/capabilities/{slug}')
def public_capability(slug: str):
    with db_cursor() as cur:
        cur.row_factory = dict_row
        cur.execute("SELECT id,name,slug,description FROM capabilities WHERE slug=%s AND is_active=true", (slug,))
        capability = cur.fetchone()
        if not capability:
            raise HTTPException(404, 'Capability not found')
        cur.execute("""
            SELECT p.slug,p.name,v.name AS vendor_name,pc.support_status,pc.limitations,pc.confidence_score,pc.last_verified_at
            FROM product_capabilities pc
            JOIN products p ON p.id=pc.product_id AND p.status='active'
            LEFT JOIN vendors v ON v.id=p.vendor_id
            WHERE pc.capability_id=%s AND pc.edition_id IS NULL
            ORDER BY p.name
        """, (capability['id'],))
        products = cur.fetchall()
    return {'capability': capability, 'products': products}

@router.get('/api/public/compare/{pair}')
def public_compare(pair: str):
    parts = pair.split('-vs-')
    if len(parts) != 2:
        raise HTTPException(404, 'Comparison not found')
    a,b = sorted(parts)
    if pair != f'{a}-vs-{b}':
        return {'canonical_pair': f'{a}-vs-{b}', 'redirect': True}
    with db_cursor() as cur:
        cur.row_factory = dict_row
        cur.execute("SELECT id,slug,name FROM products WHERE slug=ANY(%s) AND status='active'", ([a,b],))
        products = cur.fetchall()
        if len(products) != 2:
            raise HTTPException(404, 'Comparison not found')
        ids = [p['id'] for p in products]
        cur.execute("""
            SELECT p.slug AS product_slug,cap.slug AS capability_slug,cap.name AS capability_name,
                   m.name AS module_name,pc.support_status,pc.limitations,pc.confidence_score
            FROM product_capabilities pc
            JOIN products p ON p.id=pc.product_id
            JOIN capabilities cap ON cap.id=pc.capability_id
            JOIN modules m ON m.id=cap.module_id
            WHERE pc.product_id=ANY(%s) AND pc.edition_id IS NULL
            ORDER BY m.name,cap.name,p.slug
        """, (ids,))
        rows = cur.fetchall()
    return {'canonical_pair': f'{a}-vs-{b}', 'products': products, 'capabilities': rows}
