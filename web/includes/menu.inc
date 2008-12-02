
<!-- menu.inc -->
  <div class="menu">
    <table>
      <tr>
        <td class="left">
          <span class="go_xxx"><a href="%cgi_file%?db=%my_db%">new query</a></span>
          ||
          <span class="query"><TMPL_IF name="default"><strong>query</strong><TMPL_ELSE><a href="%cgi_file%?%query_string%">query</a></TMPL_IF></span>
          <TMPL_IF name="results_string">
          |
          <span class="results"><TMPL_IF name="get_results"><strong>results</strong><TMPL_ELSE><a href="%cgi_file%?%results_string%">results</a></TMPL_IF></span>
          </TMPL_IF>
          <TMPL_IF name="records_string">
          |
          <span class="records"><TMPL_IF name="show_records"><strong>records</strong><TMPL_ELSE><a href="%cgi_file%?%records_string%">records</a></TMPL_IF></span>
          </TMPL_IF>
        </td>
        <td class="right">
          <span class="go_xxx"><a href="%help_file%">help</a></span>
          <!-- |
          <span class="go_xxx"><a href="%pref_file%">preferences</a></span> -->
          ||
          <span class="go_xxx"><a href="%home_file%">lir home</a></span>
        </td>
      </tr>
    </table>
  </div> <!-- class="menu" -->
<!-- /menu.inc/ -->
