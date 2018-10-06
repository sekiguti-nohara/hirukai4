class TopsController < ApplicationController
	def slack #これは今は分けているが、本来はscrapというアクションの中に入れたい
		
	end

	def top
	end

	def scrape
# ここから下はスクレイピングのためだが、一度データベースに保存した為もう使わない
# 金曜じゃない日かつ一回保存してたらscrapeしない
		agent = Mechanize.new

		#ここをデプロイする時に変更する必要がある
		agent.user_agent_alias = 'Mac Safari 4'
		agent.get('https://connect.airregi.jp/login?client_id=SFT&redirect_uri=https%3A%2F%2Fconnect.airregi.jp%2Foauth%2Fauthorize%3Fclient_id%3DSFT%26redirect_uri%3Dhttps%253A%252F%252Fairshift.jp%252Fsft%252Fcallback%26response_type%3Dcode') do |page|

		  	mypage = page.form_with(id: 'command') do |form|
		    # ログインに必要な入力項目を設定していく
		    # formオブジェクトが持っている変数名は入力項目(inputタグ)のname属性
		    	form.username = ''
		    	form.password = ''

		  	end.submit

		  	#HTMLにしている
		  	doc = Nokogiri::HTML(mypage.content.toutf8)

		  	#jsonのデータとして情報をとってきている
			doc_j = doc.xpath("//script")[3]["data-json"]

			# 何回もログインしなくていいようにデータを保存する
			# doc_j = Datum.find(1).doc
			#jsonをhashに変換
			hash = JSON.parse doc_j
			# binding.pry
			#これがスタッフの情報
			staffs = hash["app"]["staffList"]["staff"]
			shifts = hash["app"]["monthlyshift"]["shift"]["shifts"]

			#スタッフは一週間に一回程度保存し直すようにしたい

			if Date.today.friday?
				#一回全部消して保存し直す
				Staff.destroy_all
				staffs.each do |staff|
					staff_new = Staff.new
					staff_new.air_staff_id = staff["id"]
					staff_new.name = staff["name"]["family"] + staff["name"]["first"]

					#一度保存したら保存しなくて良い
					staff_new.save
				end
			end

			if Shift.all != []
				if Shift.all.last.date == Date.today
					Shift.where(date: Date.today).destroy_all
				end
			end

			if Rest.all != []
				if Rest.all.last.day == Date.today
					Rest.where(day: Date.today).destroy_all
				end
			end

			rest_hour = 16
			rest_minute = 0
			shifts.each do |shift|
				#時間が入っていない場合がある
				#はじめに休む人の時間を設定

				if shift["workTime"]["start"] != nil
					#shift_day = DateTime.parse(shift["workTime"]["text"])

					#これによって日付をとってきている
					year = shift["date"][0,4].to_i
					month = shift["date"][4,2].to_i
					day = shift["date"][6,2].to_i

					date = Date.new(year,month,day)
					#その日の分のシフトデータだけを保存するかつ同じ日に二回シフトを保存しないようにする
					if date.today? && shift["groupId"].to_i != 0
						# 休憩テーブルも作成する

						shift_new = Shift.new

						# 始まりの時間
						start_hour = shift["workTime"]["text"][-13,2].to_i
						start_minute = shift["workTime"]["text"][-10,2].to_i

						# 終わりの時間
						end_hour = shift["workTime"]["text"][-5,2].to_i
						end_minute = shift["workTime"]["text"][-2,2].to_i

						shift_new.start = DateTime.new(year,month,day,start_hour,start_minute,0,'+09:00')
						shift_new.end = DateTime.new(year,month,day,end_hour,end_minute,0,'+09:00')
						shift_new.air_staff_id = shift["staffId"]
						shift_new.staff_id = Staff.find_by(air_staff_id: shift["staffId"]).id
						shift_new.group_id = shift["groupId"].to_i
						shift_new.date = Date.today
						shift_new.save

						working_hour = (shift_new.end - shift_new.start)/3600
						rest_new = Rest.new
						rest_new.staff_id = shift_new.staff_id
						rest_new.group_id = shift_new.group_id
						rest_new.working_hour = working_hour
						rest_new.day = Date.today

						rest_new.rest_start = DateTime.new(Date.today.year,Date.today.month,Date.today.day,rest_hour,rest_minute,0,'+09:00')
						if working_hour == 9
							rest_new.rest_time = 60
							rest_hour += 1
						elsif working_hour >= 6
							rest_new.rest_time = 30
							if rest_minute == 0
								rest_minute = 30
							else
								rest_minute = 0
								rest_hour += 1
							end
						end
						#休憩がある人だけを保存する
						if rest_new.rest_time != nil
							rest_new.save
						end
					end
				end

			end
		end





	# ここのまとまりがgoogle driveのスプレッドシートから値を取って来ている
	# 	#この３つの値が必要、ここでは環境変数を設定するためにconfigというgemを使っている。
		client_id     = ''
		client_secret = ''
		refresh_token = ''

		#    #ここからデータを取りに行っている
	    client = OAuth2::Client.new(client_id,client_secret,site: "https://accounts.google.com",token_url: "/o/oauth2/token",authorize_url: "/o/oauth2/auth")
	    auth_token = OAuth2::AccessToken.from_hash(client,{:refresh_token => refresh_token, :expires_at => 3600})
	    auth_token = auth_token.refresh!
	    session = GoogleDrive.login_with_oauth(auth_token.token)

	  # wsにスプレッドシートのデータが入っている。session.spreadsheet_by_keyはスプレッドシートを開いたときのURLの一部
	    ws = session.spreadsheet_by_key("1vvvwo43INRE8orVAjD3PZOFlTzuvIAWWyE9RrXB4HgI").worksheets[0]
	    day = Date.today

	    if TrainShift.all != []
		    if TrainShift.all.last.date == Date.today
				TrainShift.where(date: Date.today).destroy_all
			end
		end

	    ((ws.num_rows-3)/4).times do |row|
	    	# puts ws[(row+1)*4, 1]
	    	(8..ws.num_cols).each do |col|
	    	 	if Date.today == ws[(row+1)*4, col].to_date && (ws[3, col][0] == "第" || ws[3, col][0] == "O")
	    	 		train_shift = TrainShift.new
	    	 		train_shift.staff_id = Staff.find_by(name: ws[((row+1)*4)+1, col]).id
	    	 		train_shift.start = DateTime.new(day.year.to_i, day.month.to_i, day.day.to_i, ws[((row+1)*4)+2, col][0, 2].to_i, ws[((row+1)*4)+2, col][3, 2].to_i,0,'+09:00')
	    	 		train_shift.end = DateTime.new(day.year.to_i, day.month.to_i, day.day.to_i, ws[((row+1)*4)+3, col][0, 2].to_i, ws[((row+1)*4)+3, col][3, 2].to_i,0,'+09:00')
	    	 		if ws[3, col][0] == "第"
	    	 			train_shift.which = "training"
	    	 		else
	    	 			train_shift.which = "OJT"
	    	 		end
	    	 		train_shift.date = Date.today
	    	 		train_shift.save
	    		end
	    	end
	    end


	    #スラックで送信する
	    notifier = Slack::Notifier.new(
				""
		) #取得したslackのWebhook URL
		# 全員の情報
		# notifier.ping(staffs)

		# range = Date.today.beginning_of_day..Date.today.end_of_day
		today_shifts = Shift.where(date: Date.today)

		today_staffs = []
		today_shifts.each do |today_shift|
			today_staff = today_shift.staff
			today_staffs.push(today_staff.name + " ")
			today_staffs.push(today_shift.start.strftime("%H:%M")+"~"+today_shift.end.strftime("%H:%M"))
			today_staffs.push("\n")
		end

		today_rests = []
		rests = Rest.where(day: Date.today)
		rests.each do |rest|
			today_rests.push(rest.staff.name)
			today_rests.push(rest.rest_start.strftime("%H:%M")+"~"+(rest.rest_start + rest.rest_time*60).strftime("%H:%M"))
			today_rests.push("\n")
		end

		today_staffs = today_staffs.join()
		today_rests = today_rests.join()
		notifier.ping("今日のシフトです\n" + today_staffs)
		notifier.ping("今日のQAリーダです\n")
		notifier.ping("今日の休憩シフトです\n" + today_rests)
	end

	def main
		@staffs = Staff.all
		#これで今日のシフトがとれる
		# range = Date.today.beginning_of_day..Date.today.end_of_day
		# @today_shifts = Shift.where(start: range)
		@today_shifts = Shift.where(date: Date.today)

		# @rests = Rest.where(day: Date.today)

		# i = 0
		# rests.each do |rest|
		# 	if rest.group_id == "wcp"
		# 		if rest.working_hour == 9
		    		
		#      	elsif rest.working_hour >= 6
		#     		half_rest.push(today_shift.staff_id)
		#     	end
		# 	elsif rest.group_id == "wc"
		# 	end
		# end

		#じぶんのシフトを取ってみる
		my_id = Staff.find_by(name: "西川譲").air_staff_id
		@myshifts = Shift.where(air_staff_id: my_id)

		#今日の研修を持ってくる
		@today_trains = TrainShift.where(date: Date.today)
		@rests = Rest.where(day: Date.today)
	end

	def edit_rest
		@rests = Rest.where(day: Date.today)
	end

	def rest_update
	end
end










