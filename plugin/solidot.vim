
if exists('g:loaded_solidot')
    finish
endif
let g:loaded_solidot = 1

if !has('python') 
    echoerr "Error: solidot.vim plugin requires Vim to be compiled with +python"
    finish
endif

if has('win32')
    let g:thisos='windows'
elseif has('win64')
    let g:thisos='windows'
elseif has('unix')
    let g:thisos='unix'
endif

if !exists('g:solidot_proxy')
    let g:solidot_proxy=''
endif

if !exists('g:solidot_timeout')
    let g:solidot_timeout=10
endif

let s:sl_bufname = 'solidot'

function! s:SetSOLIDOTBuffer()
    if bufloaded(s:sl_bufname) > 0
        execute "sb ".s:sl_bufname
    else
        execute "new ".s:sl_bufname
    endif
    set wrap
    syn match       slSplit "^\s*\zs#.*$"
    hi def link     slSplit        Comment
    set buftype=nofile
endfunction

function! s:SOLIDOTReset()
    call s:SetSOLIDOTBuffer()
    let b:sl_cur_page=0

python << EOF

import vim
vim.current.buffer[:]=None
EOF
endfunction

function! s:Solidot(url)
    call s:SetSOLIDOTBuffer()
    let b:sl_url=a:url
    if !exists('b:sl_cur_page')
        let b:sl_cur_page=0
    endif
    let b:sl_cur_page=b:sl_cur_page+1
    let b:sl_url=b:sl_url."/page/".b:sl_cur_page
    setf config
python << EOF

import vim
import requests, re
from bs4 import BeautifulSoup
url = 'https://www.solidot.org'
headers ={'user-agent':'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/61.0.3163.79 Safari/537.36'}
thisos = str(vim.eval("g:thisos"))
def SOLIDOTShow():
    timeout = int(vim.eval("g:solidot_timeout"))
    r = requests.get(url,headers=headers, timeout=timeout)
    html = r.text
    soup = BeautifulSoup(html, "html.parser")
    for link in soup.find_all('h2'):
        if link.a != None:
            div = link.parent.parent.parent
            h2 = (div.h2)
            for a in h2.find_all('a'):
                tag = a.get('href')
                if re.search(u'story',tag):
                    #print(a.get_text())
                    vim.current.buffer.append('*' + a.get_text() + '*')
            mainnew = div.find(class_='p_mainnew')
            #print(mainnew.get_text().strip())
            if thisos == "windows":
                vim.current.buffer.append(mainnew.get_text().strip().replace('\n','').encode('gbk','ignore'))
            else:
                vim.current.buffer.append(mainnew.get_text().strip().replace('\n',''))
            vim.current.buffer.append('')


vim.current.buffer[:]=None
SOLIDOTShow()

EOF
endfunction

command! -nargs=0 Solidot        :call s:Solidot("https://www.solidot.org")
command! -nargs=0 Solidotreset   :call s:SOLIDOTReset()
