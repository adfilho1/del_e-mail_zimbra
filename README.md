# del_e-mail_zimbra

Script utilizado para remover mensagens das caixas de e-mail.
Script realiza as segintes exportações:
Exporta relação de contas.
Exporta relação de alias das contas.
Exporta relação de listas.
Exporta relação de alias das listas.
Quando solicitada remoção de mensagem de uma lista será obtida a 
relação de seus membros e executada a remoção para cada um deles,
sendo verificado antes se o membro não é uma outra lista, e em 
caso positivo será obtida a relação de membros de forma recursiva.

Para execução será necessário arquivo .csv conforme exeplo:
"4 de Outubro de 2020 07:33:54",REMETENTE@REMETENTE.COM,DESTINATARIO1@DESTINATARIO.COM;DESTINATARIO2@DESTINATARIO.COM,"ASSUNTO"
"5 de Outubro de 2020 07:21:23",REMETENTE@REMETENTE.COM,DESTINATARIO3@DESTINATARIO.COM;DESTINATARIO6DESTINATARIO.COM,"ASSUNTO"
"6 de Outubro de 2020 07:01:17",REMETENTE@REMETENTE.COM,DESTINATARIO1@DESTINATARIO.COM;DESTINATARIO2@DESTINATARIO.COM,"ASSUNTO"
