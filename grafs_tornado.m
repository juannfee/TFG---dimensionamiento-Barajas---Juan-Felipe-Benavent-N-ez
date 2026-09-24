% CODIGO 3: TORNADO POR TIPO DE PUESTO
% Genera 10 graficos (5 medios x 2 tipos).
% Estructura nueva: sensibilidad.f_TCN.Llegadas.puestos.Bajo.Quiosco.ADRM10
% Incluye: flechas de direccion + linea vertical amarilla en valor Fijo
%          + leyenda de 5 elementos.

clear; clc; close all;

% ---- Forzar fondo blanco en figuras y ejes ----
set(0, 'DefaultFigureColor', 'w');
set(0, 'DefaultAxesColor',   'w');
set(0, 'DefaultAxesXColor',  [0 0 0]);
set(0, 'DefaultAxesYColor',  [0 0 0]);
set(0, 'DefaultTextColor',   [0 0 0]);
% ------------------------------------------------

filename = 'sensibilidad.json';
if ~exist(filename, 'file')
    error('Error: no se encuentra el archivo %s.', filename);
end

try
    datos = jsondecode(fileread(filename));
catch ME
    error('Error al leer/decodificar el JSON: %s', ME.message);
end

% Esquema de color para las barras del tornado
ESQUEMA = 'A';
switch ESQUEMA
    case 'A'   % Naranja
        color10 = [0.75 0.30 0.02];
        color12 = [0.95 0.55 0.20];
    case 'B'   % Rojizo
        color10 = [0.60 0.10 0.10];
        color12 = [0.85 0.40 0.40];
    case 'C'   % Dorado
        color10 = [0.68 0.50 0.05];
        color12 = [0.90 0.75 0.35];
end
alpha12 = 0.45;

% Colores nuevos elementos
color_flecha_up   = [0.90 0.49 0.13];   % #E67E22
color_flecha_down = [0.15 0.68 0.38];   % #27AE60
color_punto       = [0.58 0.65 0.65];   % #95A5A6
color_fijo        = [0.95 0.77 0.06];   % #F1C40F

medios = {'Quiosco','PCM_UE','PCM_TCN','ABC_UE','ABC_TCN'};
medio_nombre = {'Quiosco','PCM UE','PCM TCN','ABC UE','ABC TCN'};
nM = numel(medios);

parametros = datos.parametros_orden;
nP = numel(parametros);
direcciones = {'Llegadas','Salidas'};
tipos       = {'puestos','area'};
tipo_json   = struct('puestos','puestos', 'area','areas');
tipo_titulo = struct('puestos','Número de puestos', 'area','Área (m²)');
tipo_prefijo= struct('puestos','Número de', 'area','Área de');

% Etiquetas finales de parametros (sin parentesis)
label_final = struct( ...
    'f_TCN',      'Factor reparto TCN', ...
    'f_quiosco',  'Factor uso Quiosco', ...
    'f_ABC_TCN',  'Factor reparto ABC TCN', ...
    'f_ABC_UE',   'Factor reparto ABC UE', ...
    'MQT',        'MQT', ...
    'PK',         'PK', ...
    'PT_R',       'PT registro quiosco', ...
    'PT_V',       'PT validación quiosco', ...
    'PT_PCM_UE',  'PT PCM UE', ...
    'PT_PCM_TCN', 'PT PCM TCN', ...
    'PT_ABC_UE',  'PT ABC UE', ...
    'PT_ABC_TCN', 'PT ABC TCN');

mkdir_out = 'graficos_tornado';
if ~exist(mkdir_out, 'dir'); mkdir(mkdir_out); end

for mi = 1:nM
    medio_key = medios{mi};
    medio_nom = medio_nombre{mi};

    for ti = 1:numel(tipos)
        tipo     = tipos{ti};
        tipo_key = tipo_json.(tipo);

        fig = figure('Color','w','Position',[80 80 1200 750], 'Visible','off');

        for di = 1:numel(direcciones)
            dir_name = direcciones{di};

            filas = cell(nP,1);
            for pi = 1:nP
                pkey = parametros{pi};

                try
                    b10 = datos.sensibilidad.(pkey).(dir_name).(tipo_key).Bajo.(medio_key).ADRM10;
                    a10 = datos.sensibilidad.(pkey).(dir_name).(tipo_key).Alto.(medio_key).ADRM10;
                    f10 = datos.sensibilidad.(pkey).(dir_name).(tipo_key).Fijo.(medio_key).ADRM10;
                    b12 = datos.sensibilidad.(pkey).(dir_name).(tipo_key).Bajo.(medio_key).ADRM12;
                    a12 = datos.sensibilidad.(pkey).(dir_name).(tipo_key).Alto.(medio_key).ADRM12;
                catch ME
                    warning('Error leyendo %s / %s / %s / %s: %s', ...
                        pkey, dir_name, medio_key, tipo, ME.message);
                    b10=0; a10=0; f10=0; b12=0; a12=0;
                end

                lo10 = min(b10,a10); hi10 = max(b10,a10);
                lo12 = min(b12,a12); hi12 = max(b12,a12);
                impacto = (hi10-lo10) + (hi12-lo12);

                if a10 > b10
                    dir_up = 1;
                elseif a10 < b10
                    dir_up = -1;
                else
                    dir_up = 0;
                end

                if isfield(label_final, pkey)
                    plab = label_final.(pkey);
                elseif isfield(datos.parametros_label, pkey)
                    plab = datos.parametros_label.(pkey);
                else
                    plab = pkey;
                end

                filas{pi} = struct('label', plab, ...
                                   'lo10', lo10, 'hi10', hi10, ...
                                   'lo12', lo12, 'hi12', hi12, ...
                                   'fijo', f10, ...
                                   'dir_up', dir_up, ...
                                   'impacto', impacto);
            end

            % Ordenar por impacto descendente
            impactos = cellfun(@(s) s.impacto, filas);
            [~, ord] = sort(impactos, 'descend');
            filas = filas(ord);

            ax = subplot(1,2,di); hold(ax,'on');
            set(ax, 'Color', 'w');   % fondo del area de dibujo blanco

            if di == 1
                set(ax, 'Position', [0.22, 0.13, 0.27, 0.75]);
            else
                set(ax, 'Position', [0.65, 0.13, 0.27, 0.75]);
            end

            xmax = 0;
            for pi = 1:nP
                yy = nP - pi + 1;
                f = filas{pi};

                % Barra ADRM12 (fondo)
                patch(ax, [f.lo12 f.hi12 f.hi12 f.lo12], ...
                      [yy-0.35 yy-0.35 yy+0.35 yy+0.35], ...
                      color12, 'FaceAlpha', alpha12, 'EdgeColor','none');
                % Barra ADRM10 (frente)
                patch(ax, [f.lo10 f.hi10 f.hi10 f.lo10], ...
                      [yy-0.17 yy-0.17 yy+0.17 yy+0.17], ...
                      color10, 'FaceAlpha', 1.0, 'EdgeColor','none');

                % Linea vertical amarilla en valor Fijo
                plot(ax, [f.fijo f.fijo], [yy-0.40 yy+0.40], '-', ...
                     'Color', color_fijo, 'LineWidth', 2);

                xmax = max([xmax, f.hi10, f.hi12]);
            end
            xmax = xmax * 1.18 + 1;

            % Flechas al final de la barra mas larga de cada fila
            for pi = 1:nP
                yy = nP - pi + 1;
                f = filas{pi};
                x_fin = max(f.hi10, f.hi12);
                x_txt = x_fin + 0.02*xmax;
                if f.dir_up > 0
                    text(ax, x_txt, yy, '►', 'FontSize', 13, ...
                         'Color', color_flecha_up, 'HorizontalAlignment','left', ...
                         'VerticalAlignment','middle');
                elseif f.dir_up < 0
                    text(ax, x_txt, yy, '◄', 'FontSize', 13, ...
                         'Color', color_flecha_down, 'HorizontalAlignment','left', ...
                         'VerticalAlignment','middle');
                else
                    text(ax, x_txt, yy, '●', 'FontSize', 11, ...
                         'Color', color_punto, 'HorizontalAlignment','left', ...
                         'VerticalAlignment','middle');
                end
            end

            yticks_pos = zeros(nP,1);
            yticks_lbl = cell(nP,1);
            for pi = 1:nP
                yticks_pos(pi) = nP - pi + 1;
                yticks_lbl{pi} = filas{pi}.label;
            end
            [yticks_pos_sorted, idx_sort] = sort(yticks_pos, 'ascend');
            yticks_lbl_sorted = yticks_lbl(idx_sort);

            set(ax, 'YTick', yticks_pos_sorted, 'YTickLabel', yticks_lbl_sorted, 'FontSize', 9.5);
            xlim(ax, [0 xmax]);
            ylim(ax, [0.3 nP+0.7]);
            xlabel(ax, tipo_titulo.(tipo), 'FontSize', 11);

            if strcmp(tipo,'puestos')
                paso_fino = 1;
            else
                paso_fino = max(1, round(xmax/100));
            end
            ax.XAxis.MinorTick = 'on';
            ax.XAxis.MinorTickValues = 0:paso_fino:xmax;
            ax.XMinorGrid = 'on';
            ax.XGrid = 'on';
            ax.GridAlpha = 0.18;
            ax.MinorGridAlpha = 0.10;
            box(ax,'off');
            title(ax, dir_name, 'FontSize', 12, 'FontWeight','normal');
        end

        sgtitle(sprintf('%s %s', tipo_prefijo.(tipo), medio_nom), ...
                'FontSize', 13, 'FontWeight','bold');

        % Leyenda unificada de 5 elementos
        lg_ax = axes(fig, 'Position', [0 0 1 1], 'Visible', 'off');
        hold(lg_ax, 'on');

        h1 = patch(lg_ax, NaN, NaN, color10, 'FaceAlpha', 1.0, 'EdgeColor', 'none');
        h2 = patch(lg_ax, NaN, NaN, color12, 'FaceAlpha', alpha12, 'EdgeColor', 'none');
        h3 = plot(lg_ax, NaN, NaN, '>', 'Color', color_flecha_up, ...
            'LineStyle', 'none', 'MarkerSize', 8, 'MarkerFaceColor', color_flecha_up);
        h4 = plot(lg_ax, NaN, NaN, '<', 'Color', color_flecha_down, ...
            'LineStyle', 'none', 'MarkerSize', 8, 'MarkerFaceColor', color_flecha_down);
        h5 = plot(lg_ax, NaN, NaN, '-', 'Color', color_fijo, 'LineWidth', 2);

        legend(lg_ax, [h1 h2 h3 h4 h5], ...
            {'ADRM10','ADRM12','Aumenta con el parámetro', ...
            'Disminuye con el parámetro','Valor central'}, ...
            'Position', [0.08 0.01 0.84 0.05], ...
            'Orientation', 'horizontal', 'Box', 'off', 'FontSize', 9);

        fname = fullfile(mkdir_out, sprintf('tornado_%s_%s.png', lower(medio_key), tipo));
        exportgraphics(fig, fname, 'Resolution', 200);
        close(fig);
        fprintf('Guardado: %s\n', fname);
    end
end

fprintf('\nTotal graficos generados: %d\n', nM*numel(tipos));
fprintf('Carpeta: %s\n', mkdir_out);