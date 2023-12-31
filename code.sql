-- *** В начале скрипта объекта необходимо писать поясняющий комментарий
create procedure syn.usp_ImportFileCustomerSeasonal
	-- *** Один аргумент оставляем на строке объявления
	@ID_Record int
as
set nocount on
begin
	-- *** Все переменные задаются в одном объявлении
	declare @RowCount int = (select count(*) from syn.SA_CustomerSeasonal)
	-- *** Рекомендуется при объявлении типов не использовать длину поля max
	declare @ErrorMessage varchar(max)

-- *** Отступ комментария отсутствует
-- Проверка на корректность загрузки
	if not exists (
	-- *** Отступ тела отсутствует
	select 1
	-- *** Название алиаса не соответствует стандарту (imf)
	from syn.ImportFile as f
	where f.ID = @ID_Record
		and f.FlagLoaded = cast(1 as bit)
	)
		-- *** Отступ лишний
		begin
			set @ErrorMessage = 'Ошибка при загрузке файла, проверьте корректность данных'

			raiserror(@ErrorMessage, 3, 1)
			-- *** Отсутствует пустая строка перед return
			return
		end
	-- *** Нет проверки наличия таблицы
	-- *** РЕГИСТР
	CREATE TABLE #ProcessedRows (
		ActionType varchar(255),
		ID int
	)
	
	-- *** Пробел между -- и комментарием отсутствует
	--Чтение из слоя временных данных
	select
		cc.ID as ID_dbo_Customer
		,cst.ID as ID_CustomerSystemType
		,s.ID as ID_Season
		,cast(cs.DateBegin as date) as DateBegin
		,cast(cs.DateEnd as date) as DateEnd
		,cd.ID as ID_dbo_CustomerDistributor
		,cast(isnull(cs.FlagActive, 0) as bit) as FlagActive
	into #CustomerSeasonal
	-- *** Алиас задается с помощью ключевого слова as
	from syn.SA_CustomerSeasonal cs
		-- *** Все виды join указываются явно
		join dbo.Customer as cc on cc.UID_DS = cs.UID_DS_Customer 
			and cc.ID_mapping_DataSource = 1
		join dbo.Season as s on s.Name = cs.Season
		join dbo.Customer as cd on cd.UID_DS = cs.UID_DS_CustomerDistributor
			and cd.ID_mapping_DataSource = 1
		join syn.CustomerSystemType as cst on cs.CustomerSystemType = cst.Name
	where try_cast(cs.DateBegin as date) is not null
		and try_cast(cs.DateEnd as date) is not null
		and try_cast(isnull(cs.FlagActive, 0) as bit) is not null

	-- *** Для комментариев в несколько строк используется конструкция /* */
	-- Определяем некорректные записи
	-- Добавляем причину, по которой запись считается некорректной
	select
		cs.*
		,case
			-- *** Необходимо, чтобы then был под when
			when cc.ID is null then 'UID клиента отсутствует в справочнике "Клиент"'
			when cd.ID is null then 'UID дистрибьютора отсутствует в справочнике "Клиент"'
			when s.ID is null then 'Сезон отсутствует в справочнике "Сезон"'
			when cst.ID is null then 'Тип клиента в справочнике "Тип клиента"'
			when try_cast(cs.DateBegin as date) is null then 'Невозможно определить Дату начала'
			when try_cast(cs.DateEnd as date) is null then 'Невозможно определить Дату начала'
			when try_cast(isnull(cs.FlagActive, 0) as bit) is null then 'Невозможно определить Активность'
		end as Reason
	into #BadInsertedRows
	from syn.SA_CustomerSeasonal as cs
	-- *** Отсутствует отступ join
	left join dbo.Customer as cc on cc.UID_DS = cs.UID_DS_Customer
		and cc.ID_mapping_DataSource = 1
	-- *** Не перенесён and
	left join dbo.Customer as cd on cd.UID_DS = cs.UID_DS_CustomerDistributor and cd.ID_mapping_DataSource = 1
	left join dbo.Season as s on s.Name = cs.Season
	left join syn.CustomerSystemType as cst on cst.Name = cs.CustomerSystemType
	where cc.ID is null
		or cd.ID is null
		or s.ID is null
		or cst.ID is null
		or try_cast(cs.DateBegin as date) is null
		or try_cast(cs.DateEnd as date) is null
		or try_cast(isnull(cs.FlagActive, 0) as bit) is null
		
end
