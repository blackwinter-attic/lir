
<!-- compact_query_form.inc -->
  <div class="query_form">
    <form action="%cgi_file%" method="get" accept-charset="UTF-8">
      <input type="hidden" name="action" value="get_results"></input>
      <input type="hidden" name="db" value="%my_db%"></input>
      <input type="hidden" name="record_num" value="%my_record_num%"></input>
      <input type="hidden" name="custom_ranking" value="%my_custom_ranking%"></input>
      <table>
        <tr>
          <td colspan="2">Searching database <strong>&quot;%my_db_name%&quot;</strong></td>
        </tr>
        <tr>
          <td></td>
        </tr>
        <tr>
          <td class="form_label"><label for="input_query">Query</label>:</td>
          <td>
            <input id="input_query" type="text" size="100" maxlength="250" name="query" value='%my_query%'></input>
          </td>
        </tr>
        <tr>
          <td class="form_label">Options:</td>
          <td>
            <input id="input_type" type="checkbox" name="regexp" value="1" %regexp_checked%></input>
            <label for="input_type">Regular expression</label>
            <input id="input_end-truncated" type="checkbox" name="truncated" value="1" %truncated_checked%></input>
            <label for="input_end-truncated">End-truncated</label>
            <input id="input_case_sensitive" type="checkbox" name="case_sensitive" value="1" %case_sensitive_checked%></input>
            <label for="input_case_sensitive">Case-sensitive</label>
          </td>
        </tr>
        <tr>
          <td class="form_label"><label for="select_ranking">Ranking</label>:</td>
          <td>
            <select id="select_ranking" name="ranking" size="1">
              <TMPL_LOOP name="select_ranking">
              <option value="%id%" %selected% %disabled%>%name%</option>
              </TMPL_LOOP>
            </select>
            <label for="input_threshold">Threshold</label>:
            <input id="input_threshold" type="text" size="6" maxlength="6" name="threshold" value="%my_threshold%"></input>
          </td>
        </tr>
        <tr>
          <td></td>
          <td><input type="submit" value="Search" %search_disabled%></input> <input type="reset" value="Reset"></input></td>
        </tr>
      </table>
    </form>
    <hr />
  </div> <!-- class="query_form" -->
<!-- /compact_query_form.inc/ -->
