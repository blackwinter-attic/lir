
<!-- footer.inc -->
  <div class="footer">
    <table>
      <tr>
        <td class="left">
          <em>%basename%</em> version %version% (view <a href="%cgi_file%?action=view_source">source code</a>) -- released under the <a class="ext" href="http://www.gnu.org/licenses/licenses.html#AGPL">AGPL</a><br />
          last modified %mtime% -- any feedback appreciated: jens wille <span class="email">jens.wille at gmail.com</span>
        </td>
        <td class="right">
          <span class="w3_validator"><a class="ext" href="http://validator.w3.org/check?uri=referer"><img src="%img_dir%/valid-xhtml11.gif" alt="Valid XHTML 1.1!" title="Valid XHTML 1.1!" /></a></span>
          <span class="w3_validator"><a class="ext" href="http://jigsaw.w3.org/css-validator/validator?uri=http://%http_host%/cgi-bin/parse_css.pl?local=%css_file%"><img src="%img_dir%/valid-css.gif" alt="Valid CSS!" title="Valid CSS!" /></a></span>
        </td>
      </tr>
      <tr>
        <td class="left">
          <span class="tmpl_mtime">html template last modified %tmpl_mtime%</span>
        </td>
        <td class="right">
          <TMPL_IF name="seconds"><span class="lir_seconds">%seconds% seconds</span></TMPL_IF>
        </td>
      </tr>
    </table>
  </div> <!-- class="footer" -->
<!-- /footer.inc/ -->
