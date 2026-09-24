% CODIGO 1: VALORES FIJOS

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

color10 = [0.10 0.30 0.65];
color12 = [0.85 0.45 0.15];

direcciones = {'Llegadas','Salidas'};
tipos       = {'puestos','area'};
% Mapeo tipo logico -> clave JSON
tipo_json   = struct('puestos','puestos', 'area','areas');
% Etiquetas de eje con tilde y superindice
tipo_titulo = struct('puestos','Número de puestos', 'area','Área (m²)');

mkdir_out = 'graficos_valores_fijos';
if ~exist(mkdir_out, 'dir'); mkdir(mkdir_out); end

for di = 1:numel(direcciones)
    dir_name = direcciones{di};
    for ti = 1:numel(tipos)
        tipo      = tipos{ti};
        tipo_key  = tipo_json.(tipo);

        v10 = zeros(nM,1); v12 = zeros(nM,1);
        for m = 1:nM
            m_key = medios{m};
            try
                v10(m) = datos.valores_fijos.(dir_name).(tipo_key).(m_key).ADRM10;
                v12(m) = datos.valores_fijos.(dir_name).(tipo_key).(m_key).ADRM12;
            catch ME
                warning('Error leyendo %s / %s / %s: %s', dir_name, m_key, tipo, ME.message);
                v10(m) = 0; v12(m) = 0;
            end
        end

        fig = figure('Color','w','Position',[100 100 720 460], 'Visible','off');
        ax = axes(fig); hold(ax,'on');

        b = bar(ax, [v10 v12], 'grouped');
        b(1).FaceColor = color10; b(1).EdgeColor = 'none';
        b(2).FaceColor = color12; b(2).EdgeColor = 'none';

        set(ax, 'XTick', 1:nM, 'XTickLabel', medio_labels, 'FontSize', 10);
        xtickangle(ax, 20);
        ylabel(ax, tipo_titulo.(tipo), 'FontSize', 12);
        grid(ax,'on'); ax.GridAlpha = 0.15; ax.YGrid='on'; ax.XGrid='off';
        box(ax,'off');
        legend(b, {'ADRM10','ADRM12'}, 'Location','northoutside', ...
            'Orientation','horizontal', 'Box','off');
        title(ax, sprintf('Valores fijos - %s', dir_name), ...
            'FontSize', 12, 'FontWeight','normal');

        fname = fullfile(mkdir_out, sprintf('fijos_%s_%s.png', lower(dir_name), tipo));
        exportgraphics(fig, fname, 'Resolution', 200);
        close(fig);
        fprintf('Guardado: %s\n', fname);
    end
end

fprintf('\nTotal graficos generados: %d\n', numel(direcciones)*numel(tipos));
fprintf('Carpeta: %s\n', mkdir_out);