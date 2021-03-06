class PaymentDetail < ActiveRecord::Base
  include ActionView::Helpers::NumberHelper

  belongs_to :backer

  def update_from_service
    if self.backer.payment_method == 'MoIP'
      response = request_to_moip
      process_moip_response(response) if response.present?
    end
  end

  def process_moip_response(response)
    if response["Autorizacao"].present?
      authorized  = response["Autorizacao"]

      self.payer_name  = authorized["Pagador"]["Nome"]
      self.payer_email = authorized["Pagador"]["Email"]
      self.city        = authorized["EnderecoCobranca"]["Cidade"]
      self.uf          = authorized["EnderecoCobranca"]["Estado"]

      if authorized["Pagamento"].present?
        payment                      = authorized["Pagamento"]
        self.payment_method          = payment["FormaPagamento"]
        self.net_amount              = payment["ValorLiquido"].to_f
        self.total_amount            = payment["TotalPago"].to_f
        self.service_tax_amount      = payment["TaxaMoIP"].to_f
        self.backer_amount_tax       = payment["TaxaParaPagador"].to_f
        self.payment_status          = payment["Status"]
        self.service_code            = payment["CodigoMoIP"]
        self.institution_of_payment  = payment["InstituicaoPagamento"]
        self.payment_date            = payment["Data"]
      end

      self.save!
    end
  end

  def request_to_moip
    MoIP::Client.query(backer.payment_token)
  rescue
    []
  end

  def display_service_tax
    number_to_currency service_tax_amount, :unit => "R$", :precision => 2, :delimiter => '.'
  end

  def display_net_amount
    number_to_currency net_amount, :unit => "R$", :precision => 2, :delimiter => '.'
  end

  def display_total_amount
    number_to_currency total_amount, :unit => "R$", :precision => 2, :delimiter => '.'
  end

  def display_payment_date
    I18n.l(payment_date, :format => :simple) if payment_date.present?
  end

end

# == Schema Information
#
# Table name: payment_details
#
#  id                     :integer         not null, primary key
#  backer_id              :integer
#  payer_name             :string(255)
#  payer_email            :string(255)
#  city                   :string(255)
#  uf                     :string(255)
#  payment_method         :string(255)
#  net_amount             :decimal(, )
#  total_amount           :decimal(, )
#  service_tax_amount     :decimal(, )
#  payment_status         :string(255)
#  service_code           :string(255)
#  institution_of_payment :string(255)
#  payment_date           :datetime
#  created_at             :datetime
#  updated_at             :datetime
#

