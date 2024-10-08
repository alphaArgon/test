<header>
  <h1>{{ site.title }}</h1>
</header>

<ul>
{%- for post in site.posts -%}
  <li>
    <span>{{ post.date | date: site.theme_config.date_format }}</span>
    <a href="{{ post.url | relative_url }}">{{ post.title | downcase }}</a>
    <p>{{ post.excerpt }}</p>
  </li>
{%- endfor -%}
</ul>
