require 'asciidoctor'
require 'asciidoctor/extensions'
require 'awestruct/handlers/template/asciidoc'

# Monkeypatch the AsciidoctorTemplate class from Awestruct to register Asciidoctor::Document object in page context.
# Remove this hack when issue [1] will be resolved and available in a release.
# [1] https://github.com/awestruct/awestruct/issues/288
class Awestruct::Tilt::AsciidoctorTemplate
  def evaluate(scope, locals)
    @output ||= (scope.document = ::Asciidoctor.load(data, options)).convert
  end
end

#require 'open-uri/cached'
#OpenURI::Cache.cache_path = ::File.join Awestruct::Engine.instance.config.dir, 'vendor', 'uri-cache'

Asciidoctor::Extensions.register do
  current_document = @document

  # workaround lack of docfile support for Asciidoctor base_dir option in Awestruct
  if (docfile = current_document.attributes['docfile'])
    current_document.instance_variable_set :@base_dir, (File.dirname docfile)
  end

  # TODO rewrite this as a docinfo processor
  postprocessor do
    process do |doc, output|
      next output if (doc.attr? 'page-layout') || !(doc.attr? 'site-google_analytics_account')
      account_id = doc.attr 'site-google_analytics_account'
      output
        .sub('</title>', %(</title>
<script>!function(l,p){if(l.protocol!==p){l.protocol=p}else if(l.host=="asciidoctor.netlify.com"){l.host="asciidoctor.org"}}(location,"https:")</script>))
        .rstrip.chomp('</html>').rstrip.chomp('</body>').chomp
        .concat(%(
<script>
!function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){(i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m);}(window,document,'script','//www.google-analytics.com/analytics.js','ga'),ga('create','#{account_id}','auto'),ga('send','pageview');
</script>
</body>
</html>))
    end
  end if ::Awestruct::Engine.instance.production?
end

module Awestruct
  class Engine
    def production?
      site.profile == 'production'
    end

    def development?
      site.profile == 'development'
    end

    def generate_on_access?
      site.config.options.generate_on_access
    end
  end
end
