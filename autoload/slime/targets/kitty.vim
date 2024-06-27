
function! slime#targets#kitty#config() abort
  if !exists("b:slime_config")
    let b:slime_config = {"window_id": 1, "listen_on": $KITTY_LISTEN_ON}
  end

  try
    let l:window_id = str2nr(system("kitty @ ls | jq -r '.[] | select(.is_focused) | .id'"))
    if v:shell_error || l:window_id == 0
      throw 'Error retrieving window ID'
    endif
  catch
    " Prompt user to input window ID if command fails
    let l:window_id = input("kitty window_id (current ID is $KITTY_WINDOW_ID): ", $KITTY_WINDOW_ID)
  endtry

  let b:slime_config["window_id"] = l:window_id

  " Prompt user to confirm or change the listen_on address
  let b:slime_config["listen_on"] = input("kitty listen on ($KITTY_LISTEN_ON): ", b:slime_config["listen_on"])
endfunction

function! slime#targets#kitty#send(config, text)
  let [bracketed_paste, text_to_paste, has_crlf] = slime#common#bracketed_paste(a:text)

  if bracketed_paste
    let text_to_paste = "\e[200~" . text_to_paste . "\e[201~"
  endif

  let target_cmd = s:target_cmd(a:config["listen_on"])
  call slime#common#system(target_cmd . " send-text --match id:%s --stdin", [a:config["window_id"]], text_to_paste)

  " trailing newline
  if has_crlf
    call slime#common#system(target_cmd . " send-text --match id:%s --stdin", [a:config["window_id"]], "\n")
  endif
endfunction

" -------------------------------------------------

function! s:target_cmd(listen_on)
  if a:listen_on != ""
    return "kitty @ --to " . shellescape(a:listen_on)
  end
  return "kitty @"
endfunction

