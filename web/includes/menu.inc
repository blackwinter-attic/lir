
<!-- menu.inc -->
  <div class="menu">
    <table>
      <tr>
        <td class="left">
          <span class="go_xxx"><a href="%cgi_file%?db=%my_db%">New query</a></span>
          <span class="divider">|</span>
          <span class="query"><TMPL_IF name="default"><strong>Query</strong><TMPL_ELSE><a href="%cgi_file%?%query_string%">Query</a></TMPL_IF></span>
          <TMPL_IF name="results_string">
          <span class="divider">|</span>
          <span class="results"><TMPL_IF name="get_results"><strong>Results</strong><TMPL_ELSE><a href="%cgi_file%?%results_string%">Results</a></TMPL_IF></span>
          </TMPL_IF>
          <TMPL_IF name="records_string">
          <span class="divider">|</span>
          <span class="records"><TMPL_IF name="show_records"><strong>Records</strong><TMPL_ELSE><a href="%cgi_file%?%records_string%">Records</a></TMPL_IF></span>
          </TMPL_IF>
        </td>
        <td class="right">
          <span class="go_xxx"><a href="%help_file%">Help</a></span>
          <!-- <span class="divider">|</span>
          <span class="go_xxx"><a href="%pref_file%">Preferences</a></span> -->
          <span class="divider">|</span>
          <span class="go_xxx"><a href="%home_file%">LIR home</a></span>
        </td>
      </tr>
    </table>
  </div> <!-- class="menu" -->
<!-- /menu.inc/ -->
