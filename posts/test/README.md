---
layout: page
title: Test
---

<!-- blog -->
{%- include rest/defaults.liquid -%}
{%- include common/rest/defaults.liquid -%}
<section class="section">
  <div class="container">
    <div class="row">
      {%- include templates/postssidebar.liquid -%}
    </div>
  </div>
  <div class="container">
    <div class="row">
      {% for post in site.posts %}
        {% if post.url contains page.url %}
            {% include sections/post-section.html %}
        {% endif %}
      {% endfor %}
    </div>
  </div>
</section>
