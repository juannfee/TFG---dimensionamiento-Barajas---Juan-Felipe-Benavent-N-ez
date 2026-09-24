% CODIGO 2: SENSIBILIDAD POR PARAMETRO
% Genera 24 graficos (12 parametros x 2 tipos: puestos y areas).
% Estructura nueva: sensibilidad.f_TCN.Llegadas.puestos.Bajo.Quiosco.ADRM10
% Incluye: flechas de direccion + linea vertical amarilla en valor Fijo
%          + leyenda de 5 elementos.

clear; clc; close all;

filename = 'sensibilidad.json';
if ~exist(filename, 'file')
    error('Error: no se encuentra el archivo %s.', filename);
end

try
    datos = jsondecode(fileread(filename));
catch ME
    error('Error al leer/decodificar el JSON: %s', ME.message);
end

medios = {'Quiosco','PCM_UE','PCM_TCN','ABC_UE','ABC_TCN'};
medio_labels = {'Quiosco','PCM UE','PCM TCN','ABC UE','ABC TCN'};
nM = numel(medios);

% Colores base
color12 = [0.30 0.55 0.85]; alpha12 = 0.35;
color10 = [0.06 0.24 0.55];
% Colores nuevos elementos
color_flecha_up   = [0.90 0.49 0.13];   % #E67E22 naranja -> aumenta
color_flecha_down = [0.15 0.68 0.38];   % #27AE60 verde   -> disminuye
color_punto       = [0.58 0.65 0.65];   % #95A5A6 gris    -> sin efecto
color_fijo        = [0.95 0.77 0.06];   % #F1C40F amarillo

parametros = datos.parametros_orden;
tipos      = {'puestos','area'};
tipo_json  = struct('puestos','puestos', 'area','areas');
tipo_titulo= struct('puestos','Número de puestos', 'area','Área (m²)');
direcciones= {'Llegadas','Salidas'};

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

mkdir_out = 'graficos_sensibilidad_parametros';
if ~exist(mkdir_out, 'dir'); mkdir(mkdir_out); end

for pi = 1:numel(parametros)
    pkey = parametros{pi};

    if isfield(label_final, pkey)
        plabel = label_final.(pkey);
    elseif isfield(datos.parametros_label, pkey)
        plabel = datos.parametros_label.(pkey);
    else
        plabel = pkey;
    end

    for ti = 1:numel(tipos)
        tipo     = tipos{ti};
        tipo_key = tipo_json.(tipo);

        fig = figure('Color','w','Position',[80 80 1180 560], 'Visible','off');

        for di = 1:numel(direcciones)
            dir_name = direcciones{di};
            ax = subplot(1,2,di); hold(ax,'on');

            v10_lo = zeros(nM,1); v10_hi = zeros(nM,1);
            v12_lo = zeros(nM,1); v12_hi = zeros(nM,1);
            v10_fi = zeros(nM,1);
            dir_up = zeros(nM,1);   % 1 sube, -1 baja, 0 igual

            for m = 1:nM
                m_key = medios{m};
                try
                    b   = datos.sensibilidad.(pkey).(dir_name).(tipo_key).Bajo.(m_key).ADRM10;
                    a   = datos.sensibilidad.(pkey).(dir_name).(tipo_key).Alto.(m_key).ADRM10;
                    f10 = datos.sensibilidad.(pkey).(dir_name).(tipo_key).Fijo.(m_key).ADRM10;

                    b12 = datos.sensibilidad.(pkey).(dir_name).(tipo_key).Bajo.(m_key).ADRM12;
                    a12 = datos.sensibilidad.(pkey).(dir_name).(tipo_key).Alto.(m_key).ADRM12;

                    v10_lo(m) = min(b,a);   v10_hi(m) = max(b,a);
                    v12_lo(m) = min(b12,a12); v12_hi(m) = max(b12,a12);
                    v10_fi(m) = f10;

                    if a > b
                        dir_up(m) = 1;
                    elseif a < b
                        dir_up(m) = -1;
                    else
                        dir_up(m) = 0;
                    end
                catch ME
                    warning('Error leyendo %s / %s / %s / %s: %s', ...
                        pkey, dir_name, m_key, tipo, ME.message);
                end
            end

            y = (nM:-1:1)';
            xmax = max([v10_hi; v12_hi]) * 1.18 + 1;

            for m = 1:nM
                yy = y(m);
                % Barra ADRM12 (fondo)
                patch(ax, [v12_lo(m) v12_hi(m) v12_hi(m) v12_lo(m)], ...
                      [yy-0.42 yy-0.42 yy+0.42 yy+0.42], color12, ...
                      'FaceAlpha', alpha12, 'EdgeColor','none');
                % Barra ADRM10 (frente)
                patch(ax, [v10_lo(m) v10_hi(m) v10_hi(m) v10_lo(m)], ...
                      [yy-0.20 yy-0.20 yy+0.20 yy+0.20], color10, ...
                      'FaceAlpha', 1.0, 'EdgeColor','none');

                % Linea vertical amarilla en valor Fijo
                plot(ax, [v10_fi(m) v10_fi(m)], [yy-0.45 yy+0.45], '-', ...
                     'Color', color_fijo, 'LineWidth', 2);

                % Flecha de direccion al final de la barra mas larga del par
                x_fin = max(v10_hi(m), v12_hi(m));
                x_txt = x_fin + 0.02*xmax;
                if dir_up(m) > 0
                    text(ax, x_txt, yy, '►', 'FontSize', 14, ...
                         'Color', color_flecha_up, 'HorizontalAlignment','left', ...
                         'VerticalAlignment','middle');
                elseif dir_up(m) < 0
                    text(ax, x_txt, yy, '◄', 'FontSize', 14, ...
                         'Color', color_flecha_down, 'HorizontalAlignment','left', ...
                         'VerticalAlignment','middle');
                else
                    text(ax, x_txt, yy, '●', 'FontSize', 12, ...
                         'Color', color_punto, 'HorizontalAlignment','left', ...
                         'VerticalAlignment','middle');
                end
            end

            set(ax, 'YTick', 1:nM, 'YTickLabel', flip(medio_labels), 'FontSize', 10);
            xlim(ax, [0 xmax]);
            ylim(ax, [0.3 nM+0.7]);
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

            pos = ax.Position;
            ax.Position = [pos(1) pos(2)+0.12 pos(3) pos(4)-0.12];
        end

        sgtitle(sprintf('%s - %s', plabel, tipo_titulo.(tipo)), ...
                'FontSize', 13, 'FontWeight','bold');

        % Leyenda unificada de 5 elementos en la parte inferior
        lg_ax = axes(fig, 'Position', [0 0 1 1], 'Visible', 'off');
        hold(lg_ax, 'on');
        h1 = patch(lg_ax, NaN, NaN, color10, 'FaceAlpha', 1.0, 'EdgeColor','none');
        % ...
        h1 = patch(lg_ax, NaN, NaN, color10, 'FaceAlpha', 1.0, 'EdgeColor','none');
        h2 = patch(lg_ax, NaN, NaN, color12, 'FaceAlpha', alpha12, 'EdgeColor', color12);
        h3 = plot(lg_ax, NaN, NaN, '>', 'Color', color_flecha_up, ...
            'LineStyle','none', 'MarkerSize', 8);
        h4 = plot(lg_ax, NaN, NaN, '<', 'Color', color_flecha_down, ...
            'LineStyle','none', 'MarkerSize', 8);
        h5 = plot(lg_ax, NaN, NaN, '-', 'Color', color_fijo, 'LineWidth', 2);

        legend(lg_ax, [h1 h2 h3 h4 h5], ...
            {'ADRM10','ADRM12','Aumenta con el parámetro', ...
            'Disminuye con el parámetro','Valor central'}, ...
            'Position', [0.08 0.01 0.84 0.05], ...
            'Orientation', 'horizontal', 'Box', 'off', 'FontSize', 9);

        fname = fullfile(mkdir_out, sprintf('%02d_%s_%s.png', pi, pkey, tipo));
        exportgraphics(fig, fname, 'Resolution', 180);
        close(fig);
        fprintf('Guardado: %s\n', fname);
    end
end

fprintf('\nTotal graficos generados: %d\n', numel(parametros)*numel(tipos));
fprintf('Carpeta: %s\n', mkdir_out);