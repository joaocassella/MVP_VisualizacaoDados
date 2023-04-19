create function func_imprime_indicadores_equipamentos(i140_predio_token text, i140_sistema_equipamento_token text, i140_data_inicial date, i140_data_final date) returns text
    language plpgsql
as
$$
declare

    v_log_banco                                 text;

    v140_resultado					            text;
    v140_url_imagens                            text;
    v140_predio_id                              predios.id%type;
    v140_sistema_descricao                      text;
    v140_predio_descricao                       text;
    v140_rodape                                 text;
    v140_linha                                  text;
    v140_tabela_4060                            text;
    v140_tabela_5050                            text;
    v140_texto                                  text;
    v140_total_registros                        integer;

    c140_parametros cursor for
		select services.url
		       ,predios.id
		       ,predios.descricao
          from services
		  join predios on predios.token = i140_predio_token
	cross join parametros
         where codigo = 'PASTA_IMAGENS';

    c140_cabecalho cursor for
         select '<html>
                    <meta charset="utf-8">
                    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
                    <style>
                        body, html, td, tr {
                            font-family: arial;
                            font-size: 12px !important
                        }

                        table {
                            width: 100%;
                        }

                        table tr {
                            -webkit-print-color-adjust: exact;height:30px;text-align:center;font-size:14px;
                        }
                        table td {
                            -webkit-print-color-adjust: exact;height:30px; padding: 5px;
                        }
                        .table_tabela{border:1px #000 solid; border-space: 0; border-collapse: collapse;}

                        .table_tabela
                            tr:nth-child(even){background:#eaeaea;}

                        .table_tabela
                            td {border:1px #000 solid;heigth:10px;}

                        @media print {
                            @page {
                                size: landscape;
                                margin: 3%;
                            }
                        }


						@media print {
							.pagebreak {
								clear: both;
								page-break-after: always;
							}
						}

                        .bar {
                            width: 100%;
                            font-size: 18px;
                            padding: 10px;
                            background: #c6c6c6;
                            text-align: center;
                            font-weight: bold;
                            margin-top: 30px;
                            -webkit-print-color-adjust: exact;
                        }

                        .new-page {
                            page-break-after: always;
                        }

                        .table-header {
                            border-collapse: collapse;
                            border: 5px;
                            width: 100%;
                        }

                        .img-left {
                            display: block;
                            height: 70px;
                        }

                        .img-right {
                            display: block;
                            height: 25px;
                            float: right;
                        }

                        .table-header.print-table {
                            display: none;
                        }

                        @media print {

                            .table-header.print-table {
                                display:inline-table;
                                width: 100% !important;
                                margin-bottom:10px;
                                margin-top:30px;
                            }

                            .table-header.padrao{
                                display: none;
                            }

                            .bar {
                                margin-top: 0px;
                            }
                        }
                    </style>
                    <header>
                        <table>
                        <th>
                        <td width="50%"><a style="text-decoration: none;"> <img style="display: block; height: 60px; " src="'||services.url||'/logos/clientes/'||i140_predio_token::text||'.png" /> </a></td>
                        <td width="50%"><a style="text-decoration: none;"> <img style="display: block; height: 25px; float: right;" src="'||services.url||'/logos/logomarca_relatorios.png" /> </a></td>
                        </th>
                        </table>
                        <p style="font-size:16px;">INDICADORES REF. AO PERÍODO DE '||to_char(i140_data_inicial::date,'dd/mm/yyyy')||' A '||to_char(i140_data_final::date,'dd/mm/yyyy')||'</style></p>
                    </header>
                    <body>
                ' as texto
         from services
         where services.codigo = 'PASTA_IMAGENS';

    c140_rodape cursor for
        select '
                </body>

            </html>';

    c140_pizza_execucao cursor for
         select'    <script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>

                        <script>
                            google.charts.load(''current'', {''packages'':[''corechart'']});

                            function PizzaPosicaoPlano (){

                                var tabela = new google.visualization.DataTable();
                                tabela.addColumn(''string'',''categorias'');
                                tabela.addColumn(''number'',''valores'');
                                tabela.addRows(['||
                                       '[''NO PRAZO'', '|| coalesce(totais.no_prazo,0)::text||'],'||
                                       '[''ATRASADAS'', '|| coalesce(totais.apos_prazo,0)::text||'],'||
                                       '[''ANTES DO PRAZO'', '||coalesce(totais.antes_prazo,0)::text||'],'||
                                       '[''NÃO REALIZADAS'', '||coalesce(totais.nao_realizada,0)::text||']'
                                     ||']);
                                var grafico = new google.visualization.PieChart(document.getElementById(''grafico02''));
                                var options = {pieHole: 0.4,
                                               chartArea:{left:0,top:0,width:''100%'',height:''100%''},
											   colors: [''#417400'', ''#DF7900'', ''#0038BE'', ''#FF0000'']
                                              };
                                grafico.draw(tabela, options);
                        }
                        google.charts.setOnLoadCallback(PizzaPosicaoPlano);
                        </script>
                    <body2>
                        <div id="grafico02" style="width: 100%; height: 100%"></div>
                    </body2>
               ' as texto
         from (
                  select sum(virtual.antes_prazo::numeric) as antes_prazo
                       ,sum(virtual.no_prazo::numeric) as no_prazo
                       ,sum(virtual.apos_prazo::numeric) as apos_prazo
                       ,sum(virtual.nao_realizada::numeric) as nao_realizada
                  from (
                           select case when t140_temp_dados.dt_realizada < t140_temp_dados.dt_prevista then 1
                                       else 0
                                  end as antes_prazo
                                ,case when t140_temp_dados.dt_realizada = t140_temp_dados.dt_prevista then 1
                                      else 0
                                 end as no_prazo
                                ,case when t140_temp_dados.dt_realizada > t140_temp_dados.dt_prevista then 1
                                      else 0
                                 end as apos_prazo
                                ,case when t140_temp_dados.dt_realizada is null then 1
                                      else 0
                                 end as nao_realizada
                           from t140_temp_dados
                          where t140_temp_dados.dt_prevista between i140_data_inicial and i140_data_final
                       ) virtual
              ) totais;

    c140_tab_execucao cursor for
         select '
                    <table border="1" cellspacing="0" text-align="center">
                        <thead>
                            <tr style="background-color:#E8E8E8;">
                            <th width="60%">'||case when i140_sistema_equipamento_token like 'S%' then 'SISTEMA' else 'EQUIPAMENTO' end||'</th>
                            <th width="10%">% PENDENTE</th>
                            <th width="10%">% NO PRAZO</th>
                            <th width="10%">% EXECUTADA COM ATRASO</th>
                            <th width="10%">%ANTECIPADA</th>
                            </tr>
                        </thead>'
      union all
         select '
                 <tr>
                   <td align="left">'||'<a href="'||services.url||replace(replace(encode(('{"consulta":"INDICADORES SISTEMA/EQUIPAMENTO","predio_token":"'||i140_predio_token::text||'","sistema_token":"'||subconsulta.sistema_equipamento_token||'","data_inicial":"'||i140_data_inicial||'","data_final":"'||i140_data_final||'"}')::bytea,'base64'),chr(10),''),'+','-_')||'" target="_blank">'||subconsulta.sistema_equipamento||'</a>'||'</td>
                   <td align="right">'||func_formata_numero(subconsulta.nao_realizada,2)||'</td>
                   <td align=token"right">'||func_formata_numero(subconsulta.apos_prazo,2)||'</td>
                   <td align="right">'||func_formata_numero(subconsulta.no_prazo,2)||'</td>
                   <td align="right">'||func_formata_numero(subconsulta.antes_prazo,2)||'</td>
                 </tr>'
         from (
                  select t_virtual.sistema_equipamento
                       ,t_virtual.sistema_equipamento_token
                       ,round(t_virtual.antes_prazo,2) as antes_prazo
                       ,round(t_virtual.apos_prazo,2) as apos_prazo
                       ,round(t_virtual.nao_realizada,2) as nao_realizada
                       ,round(t_virtual.no_prazo,2) as no_prazo
                  from (
                           select virtual.sistema_equipamento
                                ,virtual.sistema_equipamento_token
                                ,sum(virtual.antes_prazo::numeric)*100/sum(virtual.total::numeric) as antes_prazo
                                ,sum(virtual.no_prazo::numeric)*100/sum(virtual.total::numeric) as no_prazo
                                ,sum(virtual.apos_prazo::numeric)*100/sum(virtual.total::numeric) as apos_prazo
                                ,sum(virtual.nao_realizada::numeric)*100/sum(virtual.total::numeric) as nao_realizada
                           from (
                                  select t140_temp_dados.sistema_equipamento_descricao as sistema_equipamento
                                         ,t140_temp_dados.sistema_equipamento_token as sistema_equipamento_token
                                         ,case when t140_temp_dados.dt_realizada < t140_temp_dados.dt_prevista then 1
                                               else 0
                                          end as antes_prazo
                                         ,case when t140_temp_dados.dt_realizada = t140_temp_dados.dt_prevista then 1
                                               else 0
                                          end as no_prazo
                                         ,case when t140_temp_dados.dt_realizada > t140_temp_dados.dt_prevista then 1
                                               else 0
                                          end as apos_prazo
                                         ,case when t140_temp_dados.dt_realizada is null then 1
                                               else 0
                                          end as nao_realizada
                                         ,1 as total
                                    from t140_temp_dados
                                ) virtual
                           group by virtual.sistema_equipamento, virtual.sistema_equipamento_token
                       ) t_virtual
                  order by t_virtual.nao_realizada desc
                  limit 10
              ) subconsulta
         join services on services.codigo = 'EXECUTA_CONSULTA'
      union all
         select '
                 </table>
                ';

    c140_pizza_distribuicao cursor for
         select '<table frame="void" height="500">
					<td width="50%" align="left">
                    <div>
                        <script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>

                        <script>
                            google.charts.load(''current'', {''packages'':[''corechart'']});

                            function PizzaDistribuicaoTipos (){

                                var tabela = new google.visualization.DataTable();
                                tabela.addColumn(''string'',''categorias'');
                                tabela.addColumn(''number'',''valores'');
                                tabela.addRows(['||
               '[''CORRETIVAS'', '|| coalesce(totais.corretivas,0)::text||'],'||
               '[''PREVENTIVAS'', '|| coalesce(totais.preventivas,0)::text||'],'
             ||']);
                                var grafico = new google.visualization.PieChart(document.getElementById(''graficoDistribuicaoTipos''));
                                var options = {is3D: true,
                                               legend: { position: "top" },
											   colors: [''#FF0000'', ''#417400'']
                                              };
                                grafico.draw(tabela, options);
                        }
                        google.charts.setOnLoadCallback(PizzaDistribuicaoTipos);
                        </script>
                    </div>
                    <body3>
                        <div id="graficoDistribuicaoTipos" style="width: 100%; height: 100%"></div>
                    </body3>
				</td>
               '
         from (
                  select round(sum(case when t140_temp_dados.tipo in('PREVENTIVA','prev') then 1 else 0 end)*100 / count(t140_temp_dados.atividade_execucao_id),2) as preventivas
                       ,round(sum(case when t140_temp_dados.tipo in ('CORRETIVA', 'corr') then 1 else 0 end)*100 / count(t140_temp_dados.atividade_execucao_id),2) as corretivas
                  from t140_temp_dados
                  where t140_temp_dados.classe = 'EXECUTADA NO INTERVALO'
              ) totais;


    c140_barras_distribuicao cursor for
         select'<div>
                <head>
                    <script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
                    <script type="text/javascript">
                      google.charts.load(''current'', {''packages'':[''bar'']});
                      google.charts.setOnLoadCallback(drawChart);

                      function drawChart() {
                        var data = google.visualization.arrayToDataTable([
                          [''NÍVEIS'', ''CORRETIVAS'', ''PREVENTIVAS'', ''TOTAL''],
                ' as texto
         union all
         select '['''||totais.descricao||''', '||totais.corretivas||', '||totais.preventivas||', '||totais.total||']'|| case when totais.prioridade < 4 then ',' else '' end as texto
         from (
                  select niveis.prioridade
                       ,niveis.descricao
                       ,sum(case when atividades.tipo in('PREVENTIVA','prev') then 1 else 0 end) as preventivas
                       ,sum(case when atividades.tipo in ('CORRETIVA', 'corr') then 1 else 0 end) as corretivas
                       ,count(atividades.tipo) as total
                  from (
                           select 1 as prioridade, 'ESTABILIDADE E SEGURANÇA' as descricao
                           union all
                           select 2 as prioridade, 'DESEMPENHO' as descricao
                           union all
                           select 3 as prioridade, 'CONSERVAÇÃO' as descricao
                           union all
                           select 4 as prioridade, 'CORRIQUEIRAS' as descricao
                           order by prioridade
                       ) niveis
             left join (select t140_temp_dados.prioridade
                               ,t140_temp_dados.tipo
                          from t140_temp_dados
                         where t140_temp_dados.classe = 'EXECUTADA NO INTERVALO'
                        ) atividades on atividades.prioridade = niveis.prioridade
                  group by niveis.prioridade, niveis.descricao
              ) totais
         union all
         select ']);

                  var view = new google.visualization.DataView(data);
                  view.setColumns([0,1,
                                   { calc: "stringify",
                                     sourceColumn: 1,
                                     type: "string",
                                     role: "annotation"},
                                    2,
                                   { calc: "stringify",
                                     sourceColumn: 2,
                                     type: "string",
                                     role: "annotation" },
                                    3,
                                   { calc: "stringify",
                                     sourceColumn: 3,
                                     type: "string",
                                     role: "annotation" }
                                   ]);
                  var options = {
                    height: 400,
                    bar: {groupWidth: "100%"},
                    legend: { position: "top" },
                    colors: ["#FF0000", "#417400","0038BE"],
                  };

                  var chart = new google.visualization.ColumnChart(document.getElementById("columnchart_values"));
                  chart.draw(view, options);
                    }
                </script>
                </head>
                <body>
                    <div id="columnchart_values" style="width: 100%; height: 500px;"></div>
                </body>
              </div>
            ';

    c140_tab_distribuicao cursor for
         select '<table frame="void" height: 500px>
					<td width="50%" align="left">

                    <table border="1" cellspacing="0" text-align="center">

                        <thead>
                            <tr style="background-color:#E8E8E8;">
                            <th width="25%">'||case when i140_sistema_equipamento_token like 'S%' then 'ELEMENTO' else 'EQUIPAMENTO' end||'</th>
                            <th width="8%">% CORRETIVAS</th>
                            <th width="8%">% PREVENTIVAS</th>
                            </tr>
                        </thead>'

         union all
         select '<tr>
               <td align="left">'||subconsulta.sistema_equipamento||'</td>
               <td align="right">'||func_formata_numero(subconsulta.corretivas,2)||'</td>
               <td align="right">'||func_formata_numero(subconsulta.preventivas,2)||'</td>
               </tr>' as texto
         from (
                  select t140_temp_dados.sistema_equipamento_descricao as sistema_equipamento
                       ,round(sum(case when t140_temp_dados.tipo in ('PREVENTIVA','prev') then 1 else 0 end)*100 / count(t140_temp_dados.atividade_execucao_id),0) as preventivas
                       ,round(sum(case when t140_temp_dados.tipo in ('CORRETIVA','corr') then 1 else 0 end)*100 / count(t140_temp_dados.atividade_execucao_id),0) as corretivas
                  from t140_temp_dados
                  where t140_temp_dados.classe = 'EXECUTADA NO INTERVALO'
                  group by t140_temp_dados.sistema_equipamento_descricao
                  order by corretivas desc
                  limit 10
              ) subconsulta

         union all
         select '</table>' as texto;

    c140_tab_atraso cursor for
         select '
                        <table width="60%" margin-left="20%" border="1" cellspacing="0" text-align="center">
                            <thead>
                                <tr style="background-color:#E8E8E8;">
                                <th width="20%">'||case when i140_sistema_equipamento_token like 'S%' then 'ELEMENTO' else 'EQUIPAMENTO' end||'</th>
                                <th width="8%">ATRASO MÉDIO(DIAS)</th>
                                </tr>
                            </thead>'
         union all
         select '<tr>
               <td align="left">'||subconsulta.sistema_equipamento_descricao||'</td>
               <td align="right">'||func_formata_numero(subconsulta.tempo_medio,0)||'</td>
               </tr>' as texto
         from (
                  select t140_temp_dados.sistema_equipamento_descricao as sistema_equipamento_descricao
                         ,round(sum(t140_temp_dados.dt_realizada - t140_temp_dados.dt_prevista) / count(t140_temp_dados.atividade_execucao_id),0) as tempo_medio
                    from t140_temp_dados
                   where t140_temp_dados.classe = 'EXECUTADA NO INTERVALO'
                group by t140_temp_dados.sistema_equipamento_descricao
                order by tempo_medio desc
                   limit 10
              ) subconsulta

         union all
         select '
                    </table>
                ' as texto;

    c140_tab_falhas cursor for

         select '<table width="60%" margin-left="20%" border="1" cellspacing="0" text-align="center">
                        <thead>
                            <tr style="background-color:#E8E8E8;">
                            <th width="30%">'||case when i140_sistema_equipamento_token like 'S%' then 'ELEMENTO' else 'EQUIPAMENTO' end||'</th>
                            <th width="4%">'||to_char(now()-interval '1 month','mm/yyyy')||'</th>
                            <th width="4%">'||to_char(now()-interval '2 month','mm/yyyy')||'</th>
                            <th width="4%">'||to_char(now()-interval '3 month','mm/yyyy')||'</th>
                            <th width="4%">'||to_char(now()-interval '4 month','mm/yyyy')||'</th>
                            <th width="4%">'||to_char(now()-interval '5 month','mm/yyyy')||'</th>
                            <th width="4%">'||to_char(now()-interval '6 month','mm/yyyy')||'</th>
                            <th width="4%">'||to_char(now()-interval '7 month','mm/yyyy')||'</th>
                            <th width="4%">'||to_char(now()-interval '8 month','mm/yyyy')||'</th>
                            <th width="4%">'||to_char(now()-interval '9 month','mm/yyyy')||'</th>
                            <th width="4%">'||to_char(now()-interval '10 month','mm/yyyy')||'</th>
                            <th width="4%">'||to_char(now()-interval '11 month','mm/yyyy')||'</th>
                            <th width="4%">'||to_char(now()-interval '12 month','mm/yyyy')||'</th>
                            <th width="4%">TOTAL DE FALHAS</th>
                            </tr>
                        </thead>'
         union all
         select '<tr>
               <td align="left">'||subconsulta.sistema_equipamento||'</td>
               <td align="right">'||func_formata_numero(subconsulta.mes12,0)||'</td>
               <td align="right">'||func_formata_numero(subconsulta.mes11,0)||'</td>
               <td align="right">'||func_formata_numero(subconsulta.mes10,0)||'</td>
               <td align="right">'||func_formata_numero(subconsulta.mes9,0)||'</td>
               <td align="right">'||func_formata_numero(subconsulta.mes8,0)||'</td>
               <td align="right">'||func_formata_numero(subconsulta.mes7,0)||'</td>
               <td align="right">'||func_formata_numero(subconsulta.mes6,0)||'</td>
               <td align="right">'||func_formata_numero(subconsulta.mes5,0)||'</td>
               <td align="right">'||func_formata_numero(subconsulta.mes4,0)||'</td>
               <td align="right">'||func_formata_numero(subconsulta.mes3,0)||'</td>
               <td align="right">'||func_formata_numero(subconsulta.mes2,0)||'</td>
               <td align="right">'||func_formata_numero(subconsulta.mes1,0)||'</td>
               <td align="right">'||func_formata_numero(subconsulta.total,0)||'</td>
               </tr>' as texto
         from (
                  select coalesce(predios_ambientes.descricao||' - '||predios_equipamentos.descricao||'('||coalesce(predios_equipamentos.codigo,'')||')', elementos.descricao) as sistema_equipamento
                       ,sum(case when extract('Month' from age(now()::date, atividades_execucao.dt_realizada)) = 1 then 1 else 0 end) as mes1
                       ,sum(case when extract('Month' from age(now()::date, atividades_execucao.dt_realizada)) = 2 then 1 else 0 end) as mes2
                       ,sum(case when extract('Month' from age(now()::date, atividades_execucao.dt_realizada)) = 3 then 1 else 0 end) as mes3
                       ,sum(case when extract('Month' from age(now()::date, atividades_execucao.dt_realizada)) = 4 then 1 else 0 end) as mes4
                       ,sum(case when extract('Month' from age(now()::date, atividades_execucao.dt_realizada)) = 5 then 1 else 0 end) as mes5
                       ,sum(case when extract('Month' from age(now()::date, atividades_execucao.dt_realizada)) = 6 then 1 else 0 end) as mes6
                       ,sum(case when extract('Month' from age(now()::date, atividades_execucao.dt_realizada)) = 7 then 1 else 0 end) as mes7
                       ,sum(case when extract('Month' from age(now()::date, atividades_execucao.dt_realizada)) = 8 then 1 else 0 end) as mes8
                       ,sum(case when extract('Month' from age(now()::date, atividades_execucao.dt_realizada)) = 9 then 1 else 0 end) as mes9
                       ,sum(case when extract('Month' from age(now()::date, atividades_execucao.dt_realizada)) = 10 then 1 else 0 end) as mes10
                       ,sum(case when extract('Month' from age(now()::date, atividades_execucao.dt_realizada)) = 11 then 1 else 0 end) as mes11
                       ,sum(case when extract('Month' from age(now()::date, atividades_execucao.dt_realizada)) = 12 then 1 else 0 end) as mes12
                       ,sum(1) as total
                    from predios
               left join equipamentos_tipos on 'E-'||equipamentos_tipos.token = i140_sistema_equipamento_token
               left join equipamentos_modelos on equipamentos_modelos.equipamento_tipo_id = equipamentos_tipos.id
               left join predios_equipamentos on predios_equipamentos.modelo_id = equipamentos_modelos.id
                                             and  predios_equipamentos.predio_id = predios.id
               left join itens sistemas on 'S-'||sistemas.token = i140_sistema_equipamento_token
                    join atividades_execucao on atividades_execucao.predio_id = predios.id
                                            and extract('Month' from age(now()::date, atividades_execucao.dt_realizada)) between 1 and 12
                                            and (atividades_execucao.equipamento_id = predios_equipamentos.id or atividades_execucao.sistema_id = sistemas.id)
                    join predios_atividades on predios_atividades.id = atividades_execucao.predio_atividade_id
                                           and predios_atividades.excluido = false
                                           and predios_atividades.habilitado = true
                                           and predios_atividades.bloqueado = false
                   join predios_ambientes on predios_ambientes.id = atividades_execucao.predio_ambiente_id
              left join itens elementos on elementos.id = atividades_execucao.elemento_id
              left join itens on itens.id = predios_atividades.item_id
                  where predios.token = i140_predio_token
               group by coalesce(predios_ambientes.descricao||' - '||predios_equipamentos.descricao||'('||coalesce(predios_equipamentos.codigo,'')||')', elementos.descricao)
               order by total desc
                  limit 10
              ) subconsulta
         union all
         select '</table>
                ' as texto;

	begin -- 1o.

        v140_tabela_4060 :=
	    '
              <div>
				<table height="500px" align="top">
					<td width="40%" align="left">
                        @celula1
                    </td>
					<td width="60%" align="left">
                        @celula2
                    </td>
				</table>
              </div>
	    ';

        v140_tabela_5050 :=
	    '
              <div>
				<table height="500px" align="top">
					<td width="50%" align="left">
                        @celula1
                    </td>
					<td width="50%" align="left">
                        @celula2
                    </td>
				</table>
              </div>
	    ';

	    open c140_parametros;
	    fetch c140_parametros into  v140_url_imagens, v140_predio_id, v140_predio_descricao;
	    close c140_parametros;

        -------------------------------------------------------
        -- cria uma tabela temporária para acumular os dados
        -------------------------------------------------------
        create temporary table t140_temp_dados
            (
            atividade_execucao_id integer,
            sistema_equipamento_id integer,
            sistema_equipamento_descricao text, -- CHAMADA / GARANTIA
            sistema_equipamento_token text, -- CHAMADA / GARANTIA
            elemento_id integer,
            elemento_descricao text,
            ambiente_descricao text,
            executor text,
            terceirizado boolean,
            tipo text,
            dt_prevista date,
            dt_realizada date,
            classe text,
            prioridade integer
            );

        create index ind_tempdados_classe
            on t140_temp_dados (classe);

        insert into t140_temp_dados
            (select t140_virtual.atividade_execucao_id
                    ,t140_virtual.sistema_equipamento_id
                    ,t140_virtual.sistema_equipamento_descricao
                    ,t140_virtual.sistema_equipamento_token
                    ,t140_virtual.elemento_id
                    ,t140_virtual.elemento_descricao
                    ,t140_virtual.ambiente_descricao
                    ,t140_virtual.executor
                    ,t140_virtual.terceirizado
                    ,t140_virtual.tipo
                    ,t140_virtual.dt_prevista
                    ,t140_virtual.dt_realizada
                    ,t140_virtual.classe
                    ,t140_virtual.prioridade
             from (
                  select atividades_execucao.id as atividade_execucao_id
                         ,case when i140_sistema_equipamento_token like 'S-%' then sistemas.id
                              else predios_equipamentos.id
                         end as sistema_equipamento_id
                         ,case when i140_sistema_equipamento_token like 'S-%' then elementos.descricao
                              else predios_ambientes.descricao||' - '||predios_equipamentos.descricao ||coalesce('(' || predios_equipamentos.codigo || ')', '')
                         end as sistema_equipamento_descricao
                         ,case when i140_sistema_equipamento_token like 'S-%' then sistemas.token
                              else predios_equipamentos.token
                         end as sistema_equipamento_token
                        ,atividades_execucao.dt_prevista                         as dt_prevista
                        ,atividades_execucao.dt_realizada                        as dt_realizada
                        ,elementos.id                                            as elemento_id
                        ,elementos.descricao                                     as elemento_descricao
                        ,atividades_execucao.tipo
                        ,predios_ambientes.descricao                             as ambiente_descricao
                        ,case
                             when atividades_execucao.executor is not null then atividades_execucao.executor
                             when atividades_execucao.prestador_id is not null then prestadores.nome
                             when predios_equipes.descricao is not null then predios_equipes.descricao
                             else 'EXECUTOR NÃO DEFINIDO'
                         end                                                        as executor
                        ,case
                             when atividades_execucao.executor is not null then false
                             when atividades_execucao.prestador_id is not null then predios_users.terceirizado
                             when predios_equipes.descricao is not null then false
                             else false
                         end as terceirizado
                        ,'EXECUTADA NO INTERVALO' as classe
                        ,coalesce(itens_prioridade.prioridade,1) as prioridade
                   from predios
              left join equipamentos_tipos on 'E-' || equipamentos_tipos.token = i140_sistema_equipamento_token
              left join equipamentos_modelos on equipamentos_modelos.equipamento_tipo_id = equipamentos_tipos.id
              left join predios_equipamentos on predios_equipamentos.modelo_id = equipamentos_modelos.id
                                            and predios_equipamentos.predio_id = predios.id
              left join itens sistemas on 'S-' || sistemas.token = i140_sistema_equipamento_token
                   join atividades_execucao on atividades_execucao.predio_id = predios.id
                                           and atividades_execucao.dt_realizada between i140_data_inicial::date and i140_data_final::date
                                           and (atividades_execucao.equipamento_id = predios_equipamentos.id or
                                                atividades_execucao.sistema_id = sistemas.id)
                   join predios_atividades on predios_atividades.id = atividades_execucao.predio_atividade_id
                                          and predios_atividades.excluido = false
                                          and predios_atividades.habilitado = true
                                          and predios_atividades.bloqueado = false
                   join predios_ambientes on predios_ambientes.id = atividades_execucao.predio_ambiente_id
              left join itens elementos on elementos.id = atividades_execucao.elemento_id
              left join itens on itens.id = predios_atividades.item_id
              left join users prestadores on prestadores.id = atividades_execucao.prestador_id
              left join predios_users on predios_users.user_id = atividades_execucao.prestador_id
                                     and predios_users.predio_id = predios.id
               left join predios_equipes on predios_equipes.id = atividades_execucao.predio_equipe_id
                                        and predios_equipes.predio_id = predios.id
               left join itens_prioridade on itens_prioridade.item_id = predios_atividades.item_id
                   where predios.token = i140_predio_token
               union all
                  select atividades_execucao.id as atividade_execucao_id
                         ,case when i140_sistema_equipamento_token like 'S-%' then sistemas.id
                              else predios_equipamentos.id
                         end as sistema_equipamento_id
                         ,case when i140_sistema_equipamento_token like 'S-%' then elementos.descricao
                              else predios_ambientes.descricao||' - '||predios_equipamentos.descricao ||coalesce('(' || predios_equipamentos.codigo || ')', '')
                         end as sistema_equipamento_descricao
                         ,case when i140_sistema_equipamento_token like 'S-%' then sistemas.token
                              else predios_equipamentos.token
                         end as sistema_equipamento_token
                       , atividades_execucao.dt_prevista                         as dt_prevista
                       , atividades_execucao.dt_realizada                        as dt_realizada
                       , elementos.id                                            as elemento_id
                       , elementos.descricao                                     as elemento_descricao
                       , atividades_execucao.tipo
                       , predios_ambientes.descricao                             as ambiente_descricao
                       , case
                             when atividades_execucao.executor is not null then atividades_execucao.executor
                             when atividades_execucao.prestador_id is not null then prestadores.nome
                             when predios_equipes.descricao is not null then predios_equipes.descricao
                             else 'EXECUTOR NÃO DEFINIDO'
                      end                                                        as executor
                       , case
                             when atividades_execucao.executor is not null then false
                             when atividades_execucao.prestador_id is not null then predios_users.terceirizado
                             when predios_equipes.descricao is not null then false
                             else false
                      end                                                        as terceirizado
                      ,case when atividades_execucao.dt_realizada is null then 'NÃO EXECUTADA'
                            when atividades_execucao.dt_realizada < i140_data_inicial then 'EXECUTADA ANTES DO INTERVALO'
                            when atividades_execucao.dt_realizada > i140_data_final then 'EXECUTADA APÓS O INTERVALO'
                       end as classe
                      ,coalesce(itens_prioridade.prioridade,1) as prioridade
                  from predios
             left join equipamentos_tipos on 'E-' || equipamentos_tipos.token = i140_sistema_equipamento_token
             left join equipamentos_modelos on equipamentos_modelos.equipamento_tipo_id = equipamentos_tipos.id
             left join predios_equipamentos on predios_equipamentos.modelo_id = equipamentos_modelos.id
                                           and predios_equipamentos.predio_id = predios.id
            left join itens sistemas on 'S-' || sistemas.token = i140_sistema_equipamento_token
                 join atividades_execucao on atividades_execucao.predio_id = predios.id
                                         and atividades_execucao.dt_prevista between i140_data_inicial::date and i140_data_final::date
                                         and (atividades_execucao.dt_realizada < i140_data_inicial::date or atividades_execucao.dt_realizada < i140_data_final::date or atividades_execucao.dt_realizada is null)
                                         and (atividades_execucao.equipamento_id = predios_equipamentos.id or
                                              atividades_execucao.sistema_id = sistemas.id)
                 join predios_atividades on predios_atividades.id = atividades_execucao.predio_atividade_id
                                        and predios_atividades.excluido = false
                                        and predios_atividades.habilitado = true
                                        and predios_atividades.bloqueado = false
                 join predios_ambientes on predios_ambientes.id = atividades_execucao.predio_ambiente_id
            left join itens elementos on elementos.id = atividades_execucao.elemento_id
            left join itens on itens.id = predios_atividades.item_id
            left join users prestadores on prestadores.id = atividades_execucao.prestador_id
            left join predios_users on predios_users.user_id = atividades_execucao.prestador_id
                                   and predios_users.predio_id = predios.id
            left join predios_equipes on predios_equipes.id = atividades_execucao.predio_equipe_id
                                     and predios_equipes.predio_id = predios.id
            left join itens_prioridade on itens_prioridade.item_id = predios_atividades.item_id
                where predios.token = i140_predio_token
                  ) t140_virtual
            );

        select count(*) from t140_temp_dados into v140_total_registros;

	    open c140_cabecalho;
	    fetch c140_cabecalho into v140_resultado;
	    close c140_cabecalho;

        v140_resultado := v140_resultado||'<div class="bar">EXECUÇÃO DO PLANO DE MANUTENÇÃO</div><h2></h2>';
        v140_resultado := v140_resultado||v140_tabela_4060;

        open c140_pizza_execucao;
	    fetch c140_pizza_execucao into v140_texto;
        close c140_pizza_execucao;
        v140_resultado := replace(v140_resultado,'@celula1',v140_texto);

        v140_texto := '';
        open c140_tab_execucao;
        loop
            fetch c140_tab_execucao into v140_linha;
            exit when not found;

            v140_texto := v140_texto||v140_linha;
        end loop;
        close c140_tab_execucao;
        v140_resultado := replace(v140_resultado,'@celula2',v140_texto);

        if v140_total_registros > 0 then
            v140_resultado := v140_resultado||'
                  <div class="pagebreak"></div>
                  <div class="bar">ANÁLISE DAS MANUTENÇÕES EXECUTADAS</div>
                  <h2></h2>';

            v140_resultado := v140_resultado||v140_tabela_5050;

            open c140_pizza_distribuicao;
            fetch c140_pizza_distribuicao into v140_texto;
            close c140_pizza_distribuicao;
            v140_resultado := replace(v140_resultado,'@celula1',v140_texto);

            v140_texto := '';
            open c140_barras_distribuicao;
            loop
                fetch c140_barras_distribuicao into v140_linha;
                exit when not found;

                v140_texto := v140_texto||v140_linha;
            end loop;
            close c140_barras_distribuicao;
            v140_resultado := replace(v140_resultado,'@celula2',v140_texto);

            v140_resultado := v140_resultado||v140_tabela_5050;

            v140_texto := '';
            open c140_tab_distribuicao;
            loop
                fetch c140_tab_distribuicao into v140_linha;
                exit when not found;
                v140_texto := v140_texto||v140_linha;
            end loop;
            close c140_tab_distribuicao;
            v140_resultado := replace(v140_resultado,'@celula1',v140_texto);

            v140_texto := '';
            open c140_tab_atraso;
            loop
                fetch c140_tab_atraso into v140_linha;
                exit when not found;
                v140_texto := v140_texto||v140_linha;
            end loop;
            close c140_tab_atraso;
            v140_resultado := replace(v140_resultado,'@celula2',v140_texto);

             v140_resultado := v140_resultado ||'<div class="bar">FALHAS DOS ' || case when i140_sistema_equipamento_token like 'S%' then 'ELEMENTOS' else 'EQUIPAMENTOS' end ||' NOS ÚLTIMOS 12 MESES</div><h2></h2>';

            v140_texto := '';
            open c140_tab_falhas;
            loop
                fetch c140_tab_falhas into v140_linha;
                exit when not found;
                v140_texto := v140_texto||v140_linha;
            end loop;
            close c140_tab_falhas;
            v140_resultado := v140_resultado || v140_texto;
        end if;

	    open c140_rodape;
	    fetch c140_rodape into v140_rodape;
	    close c140_rodape;

        v140_resultado := v140_resultado||v140_rodape;

        --drop table t140_temp_dados;

        return v140_resultado;
	end;
$$;

alter function func_imprime_indicadores_equipamentos(text, text, date, date) owner to postgres;

